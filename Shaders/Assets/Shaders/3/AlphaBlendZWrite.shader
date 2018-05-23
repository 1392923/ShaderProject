/******
开启深度写入的半透明效果
为了解决当模型网格之间有互相交叉的结构时，能正确显示半透明效果。需要使用两个Pass来渲染模型：
第一个Pass开启深度写入，但不输出颜色，它的目的仅仅是为了把该模型的深度值写入深度缓冲中。
第二个Pass进行正常的透明度混合，由于上一个Pass已经得到了逐像素的正确的深度信息，该Pass就可以按照像素级别的深度排序结果进行透明渲染。
******/
Shader "Learn/3/AlphaBlendZWrite" {

	Properties{
		_Color("Color Tint",COLOR) = (1,1,1,1)
		_MainTex("Main Tex", 2D) = "while" {}
		_AlphaScale("Alpha Scale",Range(0,1)) = 1
	}

	SubShader{
		Tags {"Queue"="Transparent" "IgnoreProjector"="True" "RenderType"="Transparent"}

		Pass{
			ZWrite on	//开启深度测试，
			ColorMask 0//将深度测试结果写入缓冲区，但不输出颜色。
		}

		Pass{
			Tags {"LightMode"="ForwardBase"}

			ZWrite Off
			Blend SrcAlpha OneMinusSrcAlpha

			CGPROGRAM
			#pragma vertex vert
			#pragma fragment frag 
			#include "Lighting.cginc"

			float4 _Color;
			sampler2D _MainTex;
			float4 _MainTex_ST;
			fixed _AlphaScale;

			struct a2v {
				float4 vertex : POSITION;
				float3 normal : NORMAL;
				float4 texcoord : TEXCOORD0;
			};
			struct v2f {
				float4 pos : SV_POSITION;
				float3 worldNormal : TEXCOORD0;
				float4 worldPos : TEXCOORD1;
				float2 uv : TEXCOORD2;
			};

			v2f vert (a2v v) {
				v2f f;
				f.pos = UnityObjectToClipPos(v.vertex);
				f.worldNormal = UnityObjectToWorldNormal(v.normal);
				f.worldPos = mul(unity_ObjectToWorld, v.vertex);
				f.uv = TRANSFORM_TEX(v.texcoord, _MainTex);
				return f;
			}

			fixed4 frag(v2f f) : SV_TARGET0{
				fixed3 worldNormal = normalize(f.worldNormal);
				fixed3 worldLightDir = normalize(UnityWorldSpaceLightDir(f.worldPos));

				float4 texColor = tex2D(_MainTex, f.uv);
				fixed3 albedo = texColor.rgb * _Color.rgb;//反照率
				fixed3 ambient = UNITY_LIGHTMODEL_AMBIENT.rgb * albedo;
				fixed3 diffuse = _LightColor0.rgb * albedo.rgb * saturate(dot(worldNormal, worldLightDir));

				return fixed4 (ambient+diffuse,texColor.a * _AlphaScale);
			}

			ENDCG
		}
	}

	FallBack "Transparent/VertexLit"

}