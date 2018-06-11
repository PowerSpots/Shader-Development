// 这看起来像一个Unlit着色器，除了默认情况下该路径隐藏
Shader "Hidden/PostEffects"
{
	Properties
	{
		_MainTex ("Texture", 2D) = "white" {}

		// 我们需要在着色器中声明属性，并仅在要使用它的通道中声明该变量。 然后，我们在片段着色器中实现Hable的运算符
		_ToneMapperExposure("Tone Mapper Exposure", Range(0.0, 10.0)) = 2

	}
	SubShader
	{

		// 声明Cull、ZWrite Off，ZTest Always
		// 我们正在处理的2D图像将在屏幕上显示为两个三角形，形成一个四边形。 
		// 我们不能剔除背面，Zwrite也没有任何用处，因为没有景深
		/*Cull Off ZWrite Off ZTest Always*/
		Pass
		{
			name "Invert"
			Cull Off ZWrite Off ZTest Always Lighting Off
			CGPROGRAM
			#pragma vertex vert
			#pragma fragment frag

			#include "UnityCG.cginc"

			struct appdata
			{
				float4 vertex : POSITION;
				float2 uv : TEXCOORD0;
			};

			struct v2f
			{
				float2 uv : TEXCOORD0;
				float4 vertex : SV_POSITION;
			};

			v2f vert(appdata v)
			{
				v2f o;
				o.vertex = UnityObjectToClipPos(v.vertex);
				o.uv = v.uv;
				return o;
			}

			sampler2D _MainTex;

			fixed4 frag(v2f i) : SV_Target
			{
				fixed4 col = tex2D(_MainTex, i.uv);
				// just invert the colors
				col = 1 - col;
				return col;
			}
			ENDCG
		}
		Pass
		{
			// 在Pass中添加一个名字，需要将 Cull Off 行移动到每个Pass的顶部
			// 为了访问摄像机的深度纹理，我们需要用正确的名称（这是一个约定）声明变量，然后使用宏将其转换为灰度
			name "DebugDepth"
			Cull Off ZWrite Off ZTest Always Lighting Off

			CGPROGRAM
			#pragma vertex vert
			#pragma fragment frag
			
			#include "UnityCG.cginc"

			struct appdata
			{
				float4 vertex : POSITION;
				float2 uv : TEXCOORD0;
			};

			struct v2f
			{
				float2 uv : TEXCOORD0;
				float4 vertex : SV_POSITION;
			};

			v2f vert (appdata v)
			{
				v2f o;
				o.vertex = UnityObjectToClipPos(v.vertex);
				o.uv = v.uv;
				return o;
			}
			
			sampler2D _CameraDepthTexture;

			fixed4 frag (v2f i) : SV_Target
			{
				// 更改碎片函数的内容以显示相机的深度纹理
				fixed depth = UNITY_SAMPLE_DEPTH(tex2D(_CameraDepthTexture, i.uv)); 
				fixed4 col = fixed4(depth,depth,depth, 1.0);
				
				//fixed4 col = tex2D(_MainTex, i.uv);
				//// just invert the colors
				//col.rgb = 1 - col.rgb;
				return col;
			}
			ENDCG
		}
		// 伽玛空间项目中线性空间中的效应计算：将另一个Pass添加到判断中，并向图像效果着色器添加另一个Pass
			Pass
			{
				name "Linear"
				Cull Off ZWrite Off ZTest Always Lighting Off
				CGPROGRAM
#pragma vertex vert
#pragma fragment frag

#include "UnityCG.cginc"

				struct appdata
			{
				float4 vertex : POSITION;
				float2 uv : TEXCOORD0;
			};

			struct v2f
			{
				float2 uv : TEXCOORD0;
				float4 vertex : SV_POSITION;
			};

			v2f vert(appdata v)
			{
				v2f o;
				o.vertex = UnityObjectToClipPos(v.vertex);
				o.uv = v.uv;
				return o;
			}

			sampler2D _MainTex;

			fixed4 frag(v2f i) : SV_Target
			{
				fixed4 col = pow(tex2D(_MainTex, i.uv), 2.2);
			col = 1 - col;
			return pow(col, 1 / 2.2);
			}
				ENDCG
			}
				Pass
			{
				name "ToneMapping"
				Cull Off ZWrite Off ZTest Always Lighting Off
				CGPROGRAM
#pragma vertex vert
#pragma fragment frag

#include "UnityCG.cginc"

				struct appdata
			{
				float4 vertex : POSITION;
				float2 uv : TEXCOORD0;
			};

			struct v2f
			{
				float2 uv : TEXCOORD0;
				float4 vertex : SV_POSITION;
			};

			v2f vert(appdata v)
			{
				v2f o;
				o.vertex = UnityObjectToClipPos(v.vertex);
				o.uv = v.uv;
				return o;
			}

			sampler2D _MainTex;

			// 在要使用它的通道中声明该变量
			float _ToneMapperExposure;
			// 在片段着色器中实现Hable的运算符
			float3 hableOperator(float3 col)
			{
				float A = 0.15;
				float B = 0.50;
				float C = 0.10;
				float D = 0.20;
				float E = 0.02;
				float F = 0.30;
				return ((col * (col * A + B * C) + D * E) / (col * (col * A + B) + D * F)) - E / F;
			}

			fixed4 frag(v2f i) : SV_Target
			{
				float4 col = tex2D(_MainTex, i.uv);
				float3 toneMapped = col * _ToneMapperExposure * 4;
				toneMapped = hableOperator(toneMapped) / hableOperator(11.2);
				return float4(toneMapped, 1.0);
			}
				ENDCG
			}
	}
}
