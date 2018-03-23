// 支持多个灯光的镜面反射
Shader "Custom/SpecularShaderForwardAdd"
{	
	Properties
	{
		_DiffuseTex("Texture", 2D) = "white" {}
		_Color("Color", Color) = (1,0,0,1)
		_Ambient("Ambient", Range(0, 1)) = 0.25
		_SpecColor("Specular Material Color", Color) = (1,1,1,1) 
		_Shininess("Shininess", Float) = 10
	}
	SubShader
	{
		Pass
		{
			// 支持一个以上的光源时你需要小心的是确保ForwardAdd是一个单独的通行证，因为你不想添加多次环境光
			// 因此需要将当前驻留在子着色器中的标签和其他信息移动到新的ForwardAdd Pass内，复制并粘贴当前Pass	
			Tags{ "LightMode" = "ForwardBase" }

			CGPROGRAM
			#pragma vertex vert
			#pragma fragment frag

			// 在ForwardBase传递中的其他编译指示之后添加#pragma multi_compile_fwdbase
			#pragma multi_compile_fwdbase

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
				o.vertexWorld = mul(unity_ObjectToWorld, v.vertex);
				o.uv = TRANSFORM_TEX(v.uv, _DiffuseTex);
				float3 worldNormal = UnityObjectToWorldNormal(v.normal);
				o.worldNormal = worldNormal;
				return o;
			}

			float4 frag(v2f i) : SV_Target
			{
				float3 normalDirection = normalize(i.worldNormal);
				float3 viewDirection = normalize(UnityWorldSpaceViewDir(i.vertexWorld));
				float3 lightDirection = normalize(UnityWorldSpaceLightDir(i.vertexWorld));

				float4 tex = tex2D(_DiffuseTex, i.uv);

				float nl = max(_Ambient, dot(normalDirection, _WorldSpaceLightPos0.xyz));
				float4 diffuseTerm = nl * _Color * tex * _LightColor0;

				float3 reflectionDirection = reflect(-lightDirection, normalDirection); 
				float3 specularDot = max(0.0, dot(viewDirection, reflectionDirection)); 
				float3 specular = pow(specularDot, _Shininess);

				float4 specularTerm = float4(specular, 1) * _SpecColor * _LightColor0;
				
				float4 finalColor = diffuseTerm + specularTerm;
				return finalColor;
			}
			ENDCG
		}
				
		// 支持一个以上的光源时你需要小心的是确保ForwardAdd是一个单独的通行证，因为你不想添加多次环境光
		// 第一步，复制黏贴Pass，在ForwardBase Pass中的其他编译指示之后添加#pragma multi_compile_fwdbase
		Pass
		{
			// 第二步，将第二个Pass的标签Tag改为ForwardAdd，在标签之后添加Blend One One
			// ForwardAdd告诉编译器在第一次之后应该使用该Pass来处理任何光线，并且Blend One One设置混合模式。
			// 混合模式基本上类似于Photoshop中的图层模式。
			// 我们有不同的层次，通过不同的通道渲染，我们想要以一种合理的方式将它们融合在一起。 
			// 该公式是Blend SrcFactor DstFactor;
			//Blend One One对这两个因素都使用了一个，这意味着颜色被叠加地混合。
			Tags{ "LightMode" = "ForwardAdd" }
			Blend One One
					
			CGPROGRAM
			#pragma vertex vert
			#pragma fragment frag
			// 第二步，添加附注 #pragma multi_compile_fwdadd
			// 编译指令将利用自动多编译系统，该编译系统编译特定Pass所需的着色器的所有变体。
			#pragma multi_compile_fwdadd

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
				o.vertexWorld = mul(unity_ObjectToWorld, v.vertex);
				o.uv = TRANSFORM_TEX(v.uv, _DiffuseTex);
				float3 worldNormal = UnityObjectToWorldNormal(v.normal);
				o.worldNormal = worldNormal;
				return o;
			}

			float4 frag(v2f i) : SV_Target
			{
				float3 normalDirection = normalize(i.worldNormal);
				float3 viewDirection = normalize(UnityWorldSpaceViewDir(i.vertexWorld));
				float3 lightDirection = normalize(UnityWorldSpaceLightDir(i.vertexWorld));

				float4 tex = tex2D(_DiffuseTex, i.uv);

				// 最后一步是删除_Ambient作为ForwardAdd传递中的最小值，这意味着我们不会添加两次或更多的环境光
				float nl = max(0.0, dot(normalDirection, lightDirection));
				float4 diffuseTerm = nl * _Color * tex * _LightColor0;
				//diff.rbg += ShadeSH9(half4(i.worldNormal,1));

				//Specular implementation (Phong)
				float3 reflectionDirection = reflect(-lightDirection, normalDirection);
				float3 specularDot = max(0.0, dot(viewDirection, reflectionDirection));
				float3 specular = pow(specularDot, _Shininess);

				float4 specularTerm = float4(specular, 1) * _SpecColor * _LightColor0;
				float4 finalColor = diffuseTerm + specularTerm;
				return finalColor;
			}
			ENDCG
		}
	}
}
