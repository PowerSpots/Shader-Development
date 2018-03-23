// Upgrade NOTE: upgraded instancing buffer 'Props' to new syntax.

// 切换到 BlinnPhong 照明模型
Shader "Custom/SurfaceShaderBlinnPhong" {
	// BlinnPhong没有光泽Gloss和金属Metallic的概念，所以我们应该从属性，变量声明和surf功能中删除它们
	Properties{
		_Color("Color", Color) = (1,1,1,1)
		_MainTex("Albedo (RGB)", 2D) = "white" {}
		// 第三步，添加BlinnPhong光照模型函数使用的Shininess和Specular值作为属性
		_SpecColor("Specular Material Color", Color) = (1,1,1,1)
		_Shininess("Shininess", Range(0.03, 1)) = 0.078125
	}
		SubShader{
		Tags{ "RenderType" = "Opaque" }
		LOD 200

		CGPROGRAM
		// 第一步，将表面预编译改为BlinnPhong：
		#pragma surface surf BlinnPhong fullforwardshadows

		#pragma target 3.0

		sampler2D _MainTex;

		// 
		float _Shininess;

		struct Input {
			float2 uv_MainTex;
		};

		fixed4 _Color;

		UNITY_INSTANCING_BUFFER_START(Props)
		UNITY_INSTANCING_BUFFER_END(Props)

		// BlinnPhong light函数使用SurfaceOutput数据结构，而不是SurfaceOutputStandard
		// 第二步，更改surf函数的签名
		void surf(Input IN, inout SurfaceOutput o) 
		{
			fixed4 c = tex2D(_MainTex, IN.uv_MainTex) * _Color;
			o.Albedo = c.rgb;

			// 第四步，赋值
			o.Specular = _Shininess;
			o.Gloss = c.a;

			o.Alpha = 1.0f;
		}
	ENDCG
	}
		FallBack "Diffuse"
}
