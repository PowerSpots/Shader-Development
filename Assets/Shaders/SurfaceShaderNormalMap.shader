// Upgrade NOTE: upgraded instancing buffer 'Props' to new syntax.
Shader "Custom/SurfaceShaderNormalMap" 
{
	Properties
	{
		_Color("Color", Color) = (1,1,1,1)
		_MainTex("Albedo (RGB)", 2D) = "white" {}

		// 第一步，为法线贴图添加一个属性
		_NormalMap("Normal Map", 2D) = "bump" {}
	
		_Glossiness("Smoothness", Range(0,1)) = 0.5
		_Metallic("Metallic", Range(0,1)) = 0.0
	}
	SubShader
	{
		Tags{ "RenderType" = "Opaque" }
		LOD 200

		CGPROGRAM
		// Physically based Standard lighting model, and enable shadows on all light types
		#pragma surface surf Standard fullforwardshadows

		// Use shader model 3.0 target, to get nicer looking lighting
		#pragma target 3.0

		sampler2D _MainTex;

		// 第二步， 声明变量
		sampler2D _NormalMap;

		struct Input 
		{
			float2 uv_MainTex;
		};

		half _Glossiness;
		half _Metallic;
		fixed4 _Color;

		// Add instancing support for this shader. You need to check 'Enable Instancing' on materials that use the shader.
		// See https://docs.unity3d.com/Manual/GPUInstancing.html for more information about instancing.
		// #pragma instancing_options assumeuniformscaling
		UNITY_INSTANCING_BUFFER_START(Props)
		// put more per-instance properties here
		UNITY_INSTANCING_BUFFER_END(Props)
		void surf(Input IN, inout SurfaceOutputStandard o)
		{
			// Albedo comes from a texture tinted by color
			fixed4 c = tex2D(_MainTex, IN.uv_MainTex) * _Color;

			// 第三步，将相应的处理添加到surf函数，为法线贴图声明变量并解开法线贴图
			// 对纹理进行采样（同样，主要纹理UV也会这样做），并使用UnpackNormal函数
			// 将结果赋给表面输出数据结构的Normal成员，
			o.Normal = UnpackNormal(tex2D(_NormalMap, IN.uv_MainTex));
			o.Albedo = c.rgb;
			// Metallic and smoothness come from slider variables
			o.Metallic = _Metallic;
			o.Smoothness = _Glossiness;
			o.Alpha = c.a;
		}
		ENDCG
	}
	// 所有着色器都有一个我们回退值，用于为使用着色器的网格渲染阴影的不同着色器的名称。
	// 如果您的回退着色器丢失或损坏，则网格的阴影也将被破坏。
	// 如果网格物体的阴影缺失，这是你应该检查的东西之一
	FallBack "Diffuse"
}
