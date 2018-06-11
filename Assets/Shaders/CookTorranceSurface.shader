// Upgrade NOTE: upgraded instancing buffer 'Props' to new syntax.

Shader "Custom/CookTorranceSurface" {
	//  先从属性块和子着色器块开始
	Properties {
		_MainTex ("Base (RGB)", 2D) = "white" {}
		_ColorTint ("Color", Color) = (1,1,1,1)
		_SpecColor ("Specular Color", Color) = (1,1,1,1)
		_BumpMap ("Normal Map", 2D) = "bump" {}

		// CookRorrance镜面和Disney漫反射都使用_Roughness
		// _Subsurface仅用于迪斯尼漫反射
		_Roughness ("Roughness", Range(0,1)) = 0.5
        _Subsurface ("Subsurface", Range(0,1)) = 0.5
	}
	SubShader {
		Tags { "RenderType"="Opaque" }
		LOD 200
		
		CGPROGRAM
		// 使用CookTorrance自定义照明函数
		#pragma surface surf CookTorrance fullforwardshadows
		#pragma target 3.0

		struct Input {
			float2 uv_MainTex;
		};

		sampler2D _MainTex;
        sampler2D _BumpMap;
		float _Roughness;

		// 子表面和表面颜色变量
        float _Subsurface;
		float4 _ColorTint;

		// 声明变量PI
        #define PI 3.14159265358979323846f

		UNITY_INSTANCING_BUFFER_START(Props)
		UNITY_INSTANCING_BUFFER_END(Props)
		
		// SurfaceOutputCustom结构的成员数量少于标准结构
        struct SurfaceOutputCustom {
			float3 Albedo;
			float3 Normal;
			float3 Emission;
			float Alpha;
		};

		// 实用函数：求平方值
        float sqr(float value) 
        {
            return value * value;
        }
		// 实用函数：求SchlickFresnel近似值，由diffuse和specular使用
        float SchlickFresnel(float value)
		{
		    float m = clamp(1 - value, 0, 1);
		    return pow(m, 5);
		}
		// 实用函数：几何函数使用的G1函数
        float G1 (float k, float x)
        {
             return x / (x * (1 - k) + k);
        }

        //Disney Diffuse 漫反射模块
        inline float3 DisneyDiff(float3 albedo, float NdotL, float NdotV, float LdotH, float roughness){
            float albedoLuminosity = 0.3 * albedo.r 
                                   + 0.6 * albedo.g  
                                   + 0.1 * albedo.b; // luminance approx.

		    float3 albedoTint = albedoLuminosity > 0 ? 
                                albedo/albedoLuminosity : 
                                float3(1,1,1); // normalize lum. to isolate hue+sat
            
		    float fresnelL = SchlickFresnel(NdotL);
            float fresnelV = SchlickFresnel(NdotV);

		    float fresnelDiffuse = 0.5 + 2 * sqr(LdotH) * roughness;

		    float diffuse = albedoTint 
                          * lerp(1.0, fresnelDiffuse, fresnelL) 
                          * lerp(1.0, fresnelDiffuse, fresnelV);

            float fresnelSubsurface90 = sqr(LdotH) * roughness;

		    float fresnelSubsurface = lerp(1.0, fresnelSubsurface90, fresnelL) 
                                    * lerp(1.0, fresnelSubsurface90, fresnelV);

		    float ss = 1.25 * (fresnelSubsurface * (1 / (NdotL + NdotV) - 0.5) + 0.5);

            return saturate(lerp(diffuse, ss, _Subsurface) * (1/PI) * albedo);
        }

		// 用于区域灯光, 它比原来的更均匀，更便宜
        float3 FresnelSchlickFrostbite (float3 F0, float F90, float u)
        {
            return F0 + (F90 - F0) * pow (1 - u, 5) ;
        }

        inline float DisneyFrostbiteDiff(float NdotL, float NdotV
                                        , float LdotH, float roughness)
        {
            float energyBias = lerp (0, 0.5, roughness) ;
            float energyFactor = lerp (1.0, 1.0/1.51, roughness ) ;
            float Fd90 = energyBias + 2.0 * sqr(LdotH) * roughness ;
            float3 F0 = float3 (1 , 1 , 1) ;
            float lightScatter = FresnelSchlickFrostbite (F0, Fd90, NdotL).r ;
            float viewScatter = FresnelSchlickFrostbite (F0, Fd90, NdotV).r ;
            return lightScatter * viewScatter * energyFactor;
        }

        // CookTorrance的镜面实现
		// 接受n⋅l，l⋅h，n⋅h，n⋅v，粗糙度roughness和F0镜面颜色，并根据前面的公式，计算F，D和G项。
		inline float3 CookTorranceSpec(float NdotL, float LdotH, float NdotH, float NdotV, float roughness, float F0){
			float alpha = sqr(roughness);
            float F, D, G;

			// D
			// 修改后的GGX NDF，公式见p178
			float alphaSqr = sqr(alpha);
			float denom = sqr(NdotH) * (alphaSqr - 1.0) + 1.0f;
			D = alphaSqr / (PI * sqr(denom));

			// F 菲涅耳项的应用
			// 这是CookTorrance中使用的Schlick Fresnel，它与迪斯尼漫反射相同的部分是在一个功能函数中实现的
			float LdotH5 = SchlickFresnel(LdotH);
			F = F0 + (1.0 - F0) * LdotH5;

			// G
			// 修改的Schlick几何G  为了更好地遵循Smith几何G，变量k和粗糙度_Roughness
			// 几何术语的实现，Schlick的Smith近似
            float r = _Roughness + 1;
			float k = sqr(r) / 8;
            float g1L = G1(k, NdotL);
            float g1V = G1(k, NdotV);
            G = g1L * g1V;
            
            float specular = NdotL * D * F * G;
			return specular;
		}

		// 第一步，我们需要创建实现自定义照明所需的两个函数inline void LightingCookTorrance_GI 和 inline fixed4 LightingCookTorrance 
        inline void LightingCookTorrance_GI (
			SurfaceOutputCustom s,
			UnityGIInput data,
			inout UnityGI gi)
		{
			gi = UnityGlobalIllumination (data, 1.0, s.Normal);
		}

		// 第一步，我们需要创建实现自定义照明所需的两个函数inline void LightingCookTorrance_GI 和 inline fixed4 LightingCookTorrance 
		// 计算我们需要的大部分变量，然后将它们传递给漫反射和镜面反射函数
		inline float4 LightingCookTorrance (SurfaceOutputCustom s, float3 viewDir, UnityGI gi){
            UnityLight light = gi.light;

			viewDir = normalize ( viewDir );
			float3 lightDir = normalize ( light.dir );
			s.Normal = normalize( s.Normal );
			
			float3 halfV = normalize(lightDir+viewDir);
			float NdotL = saturate( dot( s.Normal, lightDir ));
			float NdotH = saturate( dot( s.Normal, halfV ));
			float NdotV = saturate( dot( s.Normal, viewDir ));
			float VdotH = saturate( dot( viewDir, halfV ));
            float LdotH = saturate( dot( lightDir, halfV ));

			// 在自定义光照函数计算我们最需要的值，将实际的镜面反射和漫反射计算抽象在它们自己的函数中，保证模块化
			// 通过这种方式，您可以轻松地为另一个切换漫反射或镜面反射，同时只更改自定义照明功能中最少的代码行
			// BRDFs
			float3 diff = DisneyDiff(s.Albedo, NdotL,  NdotV, LdotH, _Roughness);
			float3 spec = CookTorranceSpec(NdotL, LdotH, NdotH, NdotV, _Roughness, _SpecColor);
			float3 diff2 = (DisneyFrostbiteDiff(NdotL, NdotV, LdotH, _Roughness) * s.Albedo)/PI;

			// Adding diffuse, specular and tints (light, specular)    
			float3 firstLayer = ( diff + spec * _SpecColor) * _LightColor0.rgb;
            float4 c = float4(firstLayer, s.Alpha);

			#ifdef UNITY_LIGHT_FUNCTION_APPLY_INDIRECT
				c.rgb += s.Albedo * gi.indirect.diffuse;
			#endif
			
            return c;
		}

		void surf (Input IN, inout SurfaceOutputCustom o) {
			float4 c = tex2D (_MainTex, IN.uv_MainTex) * _ColorTint;
			o.Albedo = c.rgb;
			o.Normal = UnpackNormal( tex2D ( _BumpMap, IN.uv_MainTex ) );
			o.Alpha = c.a;
		}
		ENDCG
	}
	FallBack "Diffuse"
}
