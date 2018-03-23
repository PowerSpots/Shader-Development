Shader "Unlit/MonochromeShader"
{
	/*Properties
	{
		_MainTex ("Texture", 2D) = "white" {}
	}*/

	//  硬编码值不是一个好习惯，所以我们将这个红色着色器转换为可以是我们想要的任何颜色的着色器。
	// 要做到这一点，我们需要重新引入属性块。我们需要一个颜色属性。

	// 第一步是将该属性块添加回文件中：
	// 属性块由_Name（“Description”，Type）=默认值组成。 有许多不同类型的属性，包括纹理，颜色，范围和数字。
	// 现在，着色器会进行编译，但您选择的颜色将不会被使用。 这是因为我们还没有声明和使用_Color变量。 
	Properties
	{
		_Color("Color", Color) = (1,0,0,1) 
	}

	SubShader
	{
		Tags { "RenderType"="Opaque" }
		/*LOD 100*/

		Pass
		{
			CGPROGRAM
			#pragma vertex vert
			#pragma fragment frag
			// make fog work
			/*#pragma multi_compile_fog*/
			
			#include "UnityCG.cginc"

			struct appdata
			{
				float4 vertex : POSITION;
				/*float2 uv : TEXCOORD0;*/
			};

			struct v2f
			{
				/*float2 uv : TEXCOORD0;
				UNITY_FOG_COORDS(1)*/
				float4 vertex : SV_POSITION;
			};

			/*sampler2D _MainTex;
			float4 _MainTex_ST;*/
			// 第二步，首先在CGPROGRAM语句之后的某处添加声明：
			fixed4 _Color;

			
			v2f vert (appdata v)
			{
				v2f o;
				// 在顶点函数中，有一个从对象空间转换顶点位置，直接到剪辑空间。
				// 这意味着顶点位置已经从三维坐标空间投影到不同的三维坐标空间，这更适合于数据将要经过的下一组计算。 
				// UnityObjectToClipPos是做这种翻译的函数。
				o.vertex = UnityObjectToClipPos(v.vertex);
				/*o.uv = TRANSFORM_TEX(v.uv, _MainTex);
				UNITY_TRANSFER_FOG(o,o.vertex);*/
				return o;
			}
			
			fixed4 frag (v2f i) : SV_Target
			{
				//// sample the texture
				//fixed4 col = tex2D(_MainTex, i.uv);
				//// apply fog
				//UNITY_APPLY_FOG(i.fogCoord, col);
				//return col;

				// col变成 fixed4（1,0,0,1）。 fixed4是一个包含四个固定精度的十进制数的类型
				// 我们选择哪个精度并不重要，但如果您想在不损坏保真度的情况下从更高性能中提取更多性能，这将会很重要。
				// 在这个位置，作为着色器输出的最终颜色，向量的第一个分量是红色，第二个分量是绿色，第三个蓝色和第四个alpha值。
				// 请记住，alpha通常会被忽略，除非你在透明队列中渲染。

				// 删除了片段函数中的大部分代码，因为它不再相关。只需要在着色器中留下实际有用的代码就可以保持整洁并留意。
				// 更进一步，我们可以消除与雾渲染有关的任何事情，因为我们正在对最终颜色进行硬编码。最后的着色器，删除了所有多余的计算和选项。
				/*return fixed4(1, 0, 0, 1);*/

				// 最后，更改fragment函数中的return语句，以便实际使用_Color变量：
				// 现在您可以从“材质检查器”面板中选择一种颜色
				return _Color;
			}
			ENDCG

			// 正如你所看到的，任何与纹理和雾相关的东西都已被删除。通过首先计算顶点的位置，剩下的部分负责将三角形栅格化为像素。
			// 栅格化部分在GPU中实现时不可见，并且不可编程。
			// 下一步（自动发生）是将Clip Space顶点位置传递给GPU（位于顶点和片段着色器之间）的光栅化器功能。
			// 光栅化器的输出将是属于片段的内插值（像素位置，顶点颜色等）。
			// 这个包含在v2f结构中的内插数据将被传递给片段着色器。片段着色器将使用它来计算每个片段的最终颜色。
		}
	}
}
