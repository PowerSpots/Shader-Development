Shader "Custom/SpecularShader"
{
	Properties
	{
		_DiffuseTex("Texture", 2D) = "white" {}
		_Color("Color", Color) = (1,0,0,1)
		_Ambient("Ambient", Range(0, 1)) = 0.25

		// 第一步，将两个新属性添加到属性块
		// _SpecColor是镜面的颜色，并使用白色作为默认值; _Shininess是镜面的强度，它是一个数字
		_SpecColor("Specular Material Color", Color) = (1,1,1,1) 
		_Shininess("Shininess", Float) = 10
	}
	SubShader
	{
		Tags{ "LightMode" = "ForwardBase" }
		LOD 100

		Pass
		{
			CGPROGRAM
			#pragma vertex vert
			#pragma fragment frag

			#include "UnityCG.cginc"
			#include "UnityLightingCommon.cginc"

			struct appdata
			{
				float4 vertex : POSITION;
				float3 normal : NORMAL;
				float2 uv : TEXCOORD0;
			};

			struct v2f
			{
				float2 uv : TEXCOORD0;
				float4 vertexClip : SV_POSITION;

				// 第二步，将成员添加到v2f结构中。 
				// 你需要在顶点着色器中计算额外的值，然后通过v2f将片段着色器传递给它们。
				// 额外的值是世界空间顶点位置 vertexWorld
				// 这样做是因为需要计算片段着色器中的光线方向。在片段着色器中进行光照计算，结果看起来会更好。
				float4 vertexWorld : TEXCOORD2;

				float3 worldNormal : TEXCOORD1;
			};

			sampler2D _DiffuseTex;
			float4 _DiffuseTex_ST;
			float4 _Color;
			float _Ambient;
			float _Shininess;

			v2f vert(appdata v)
			{
				v2f o;
				o.vertexClip = UnityObjectToClipPos(v.vertex);

				// 第三步，在顶点着色器中为世界空间顶点位置赋值
				// 使用矩阵乘法将局部空间顶点位置转换为世界空间顶点位置。unity_ObjectToWorld是需要进行此转换的矩阵
				o.vertexWorld = mul(unity_ObjectToWorld, v.vertex);

				o.uv = TRANSFORM_TEX(v.uv, _DiffuseTex);
				float3 worldNormal = UnityObjectToWorldNormal(v.normal);
				o.worldNormal = worldNormal;
				return o;
			}

			float4 frag(v2f i) : SV_Target
			{
				// 第四步，向片段函数添加所需的行
				// 需要计算归一化的世界空间法线，归一化的视图方向和归一化的光线方向
				// 为了获得最佳结果，所有的矢量需要在变换之后进行归一化
				float3 normalDirection = normalize(i.worldNormal);
				float3 viewDirection = normalize(UnityWorldSpaceViewDir(i.vertexWorld));
				float3 lightDirection = normalize(UnityWorldSpaceLightDir(i.vertexWorld));

				float4 tex = tex2D(_DiffuseTex, i.uv);

				float nl = max(_Ambient, dot(normalDirection, _WorldSpaceLightPos0.xyz));
				float4 diffuseTerm = nl * _Color * tex * _LightColor0;

				// 第五步，在diffuse实现之后，需要将Specular解释中的伪代码行转换为有效的Unity着色器代码
				// 首先你使用反射函数reflect找到reflectionDirection，你需要取反lightDirection，所以它从物体转向光源
				// 然后计算viewDirection和reflectionDirection之间的点积，这与用来计算漫反射项中反射离开曲面的光量相同。
				// 在镜面反射中，它位于镜面反射方向和视角方向之间，因为镜面项是视图相关的。点积值不能为负值。
				float3 reflectionDirection = reflect(-lightDirection, normalDirection); 
				float3 specularDot = max(0.0, dot(viewDirection, reflectionDirection)); 
				float3 specular = pow(specularDot, _Shininess);
				// 第六步，将镜面反射镜添加到最终输出中，乘以镜面反射颜色。
				float4 specularTerm = float4(specular, 1) * _SpecColor * _LightColor0;
				
				float4 finalColor = diffuseTerm + specularTerm;
				return finalColor;
			}
			ENDCG
		}
	}
}
