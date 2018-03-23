Shader "Custom/SurfaceShader" {
	Properties {
		_Color ("Color", Color) = (1,1,1,1)
		_MainTex ("Albedo (RGB)", 2D) = "white" {}

		// 使用标准照明模型最常见的是需要更多的纹理。 让我们添加第二个反照率纹理，然后根据滑块在两者之间进行lerp。
		// 第一步，添加第二个反射率纹理的属性和滑块
		_SecondAlbedo("Second Albedo (RGB)", 2D) = "white" {}
		_AlbedoLerp("Albedo Lerp", Range(0,1)) = 0.5

		_Glossiness ("Smoothness", Range(0,1)) = 0.5
		_Metallic ("Metallic", Range(0,1)) = 0.0
	}
	SubShader {
		Tags { "RenderType"="Opaque" }
		LOD 200

		CGPROGRAM
		// Physically based Standard lighting model, and enable shadows on all light types
		// 表面编译指示要求将表面函数作为第一个参数。
		// surf 是表面函数，Standard 是照明模式，而fullforwardshadows是一个选项
		#pragma surface surf Standard fullforwardshadows

		// Use shader model 3.0 target, to get nicer looking lighting
		#pragma target 3.0

		sampler2D _MainTex;

		// 第二步，为第二个反射率纹理添加变量声明。
		// 如果纹理具有相同的UV（并且应该，因为适用相同的模型），不需要为Input结构添加另一组UV纹理
		sampler2D _SecondAlbedo; 
		half _AlbedoLerp;

		// 此着色器中的Input结构仅包含UV，它是为顶点输出函数v2f保留的角色的一部分
		struct Input {
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

		// surf函数用于准备必要的数据，然后将其分配给数据结构。
		// SurfaceOutputStandard具有inout作为类型限定符，这意味着它是一种输入也是一种输出数据结构，将被发送到照明功能。
		void surf (Input IN, inout SurfaceOutputStandard o) {
			// Albedo comes from a texture tinted by color
			fixed4 c = tex2D (_MainTex, IN.uv_MainTex);

			// 第三步， 对第二个反照率纹理进行采样并在两个反照率纹理之间取样
			// 使用相同的UV查找第二个纹理，然后将二者的结果分配给反射率输出
			fixed4 secondAlbedo = tex2D(_SecondAlbedo, IN.uv_MainTex); 
			o.Albedo = lerp(c, secondAlbedo, _AlbedoLerp)  * _Color;

			// Metallic and smoothness come from slider variables
			o.Metallic = _Metallic;
			o.Smoothness = _Glossiness;
			o.Alpha = c.a;
		}
		ENDCG
	}
	FallBack "Diffuse"
}
