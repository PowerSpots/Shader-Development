Shader "Custom/DiffuseShader"
{
	Properties
	{
		_Color("Color", Color) = (1,0,0,1)

		// 纹理1：添加纹理属性
		_DiffuseTex("Texture", 2D) = "white" {}

		// 环境光1：添加环境光属性
		// 让我们调用这个属性_Ambient，范围为0到1，默认值为0.25。 
		_Ambient("Ambient", Range(0, 1)) = 0.25
	}

	SubShader
	{
		/*Tags{ "RenderType" = "Opaque" }*/
		// 第一步，修改标签部分
		// 这意味着此通道将用于前向渲染器的第一道光线通过。
		// 如果我们只有一个ForwardBase通行证，那么第一道光线之后的任何光线都不会影响最终结果。 
		// 如果我们希望之后的光线影响最终结果，我们需要添加另一个通行证并将其标签设置为： Tags { "LightMode" = "ForwardAdd" } 
		Tags{ "LightMode" = "ForwardBase" }
		LOD 100
		Pass
		{
			CGPROGRAM
			#pragma vertex vert
			#pragma fragment frag

			// 第二步，将另一个 include 添加到文件中的适当位置
			// UnityLightingCommon.cginc 包含许多可用于照明着色器的有用变量和函数
			#include "UnityLightingCommon.cginc" 
			#include "UnityCG.cginc"

			// 法线和光线方向需要位于一个坐标空间中。因为光线在我们渲染的模型之外，所以不应该使用对象空间
			// 用于这些照明计算的适当空间是世界空间

			// 第三步，我们需要从渲染器获取法线信息。因此，我们需要为该法线添加一个插槽到appdata，该数据结构包含我们从渲染器请求的信息。
			// 注意，需要通过将NORMAL语义添加到声明中来获得法线; 否则，渲染器无法理解我们想要添加的内容。
			struct appdata
			{
				float4 vertex : POSITION;
				float3 normal : NORMAL;

				// 纹理2：然后，为appdata中的纹理坐标添加一个插槽
				float2 uv : TEXCOORD0;
			};

			// 第五步，然后我们需要将世界空间的法线分配给输出结构。 
			// 要做到这一点，我们需要添加该插槽，使用TEXCOORD0语义来指示它使用适合三个或四个值的矢量的插槽。
			struct v2f
			{
				float4 vertex : SV_POSITION;
				float3 worldNormal : TEXCOORD0;

				// 纹理3：
				// 在v2f中，由于我们已经在世界法线的情况下使用了TEXCOORD0语义，所以我们需要将其转换为TEXCOORD1
				// 因为我们要求GPU在该数据结构中为我们提供插值纹理UV，但我们可以访问的纹理内插器的数量是有限的
				float2 uv : TEXCOORD1;
			};

			float4 _Color;

			// 纹理4：为纹理添加变量
			sampler2D _DiffuseTex;
			float4 _DiffuseTex_ST;

			// 环境2：为环境光添加变量
			// 创建一个float _Ambient的变量
			// 我们将这个变量代替0作为max函数的第一个参数，在那里我们计算我们的nl变量
			float _Ambient;

			// 第四步，使用我们刚刚通过appdata传递给顶点着色器的对象空间法线方向，并将其转换为世界空间
			// 顶点函数将计算世界空间中的法线方向，有一个UnityObjectToWorldNormal的函数
			v2f vert(appdata v)
			{
				v2f o;

				// 纹理5：
				// 这是缩放和补偿纹理坐标的宏。这样，在这里将应用有关比例和偏移的材料属性的任何变化。 
				// 这也是我们声明_DiffuseTex_ST的原因，因为TRANSFORM_TEX需要它。
				o.uv = TRANSFORM_TEX(v.uv, _DiffuseTex);

				o.vertex = UnityObjectToClipPos(v.vertex);
				float3 worldNormal = UnityObjectToWorldNormal(v.normal); // 计算世界空间的法线
				o.worldNormal = worldNormal; // 赋值给输出结构
				return o;
			}

			// 最后，我们可以使用上面的信息来计算我们的朗伯散射。
			// 我们可以从 来自额外包含文件的变量 _LightColor0 和 来自变量_WorldSpaceLightPos0的场景中第一束光线的世界空间光线位置 来获取光源颜色。
			// 当你想访问矢量的一个子集时，可以在点后面添加r，g，b，a或者x，y，z，w。 这意味着直接访问向量所包含的数字。

			// 在片段着色器中，我们需要首先将worldNormal归一化，因为变换的结果可能不是1级矢量。
			// 然后我们计算法线和光线方向的点积，注意用max函数不要让它变为负值。 
			// 最后，我们将该点积乘以表面的颜色和光的颜色。
			float4 frag(v2f i) : SV_Target
			{
				float3 normalDirection = normalize(i.worldNormal);

				//
				// 纹理6：
				// 我们需要添加一行来对纹理进行采样，然后我们需要使用这个纹理以及漫反射计算和已经存在的_Color属性。
				float4 tex = tex2D(_DiffuseTex, i.uv);

				float nl = max(_Ambient, dot(normalDirection, _WorldSpaceLightPos0.xyz));

				// 纹理7：
				// 我们通过将_Color与纹理样本颜色以及法向和光线方向的点积相乘来获得最终颜色
				float4 diffuseTerm = nl * _Color * tex * _LightColor0;
				return diffuseTerm;
			}
			ENDCG
		}
	}
}

