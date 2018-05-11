/*****
单纹理漫反射高光着色器


******/
Shader "Learn/2/SingleTexture" {

	Properties {
		_Color("Color", COLOR) = (1,1,1,1)
		_MainTex("MainTex", 2D) = "while" {}
		_Specular("Specular", COLOR) = (1,1,1,1)
		_Gloss("Gloss", Range(1, 256)) = 20
	}

	SubShader{
		Tags {"LightMode"="ForwardBase"}
		Pass{
			CGPROGRAM
			#pragma vertex vert 
			#pragma fragment frag 

			#include "Lighting.cginc"

			float4 _Color;
			sampler2D _MainTex;
			float4 _MainTex_ST;
			float4 _Specular;
			fixed _Gloss;

			struct a2v {
				float4 vertex : POSITION;
				float3 normal : NORMAL;
				float4 texcoord : TEXCOORD0;
			};

			struct v2f {
				float4 clipPos : SV_POSITION;
				float2 uv : TEXCOORD0;
				float3 worldNormal :TEXCOORD1;
				float3 worldLight : TEXCOORD2;
				float3 worldPos : TEXCOORD3;
			};

			v2f vert (a2v v ){
				v2f f ;
				f.clipPos = UnityObjectToClipPos(v.vertex);//模型转裁剪空间
				//TRANSFORM_TEX == v.texcoord * _MainTex_ST.xy + _MainTex_ST.zw;
				f.uv = TRANSFORM_TEX(v.texcoord, _MainTex);//坐标映射
				f.worldNormal = UnityObjectToWorldNormal(v.normal);//法线 世界空间
				f.worldLight = UnityWorldSpaceLightDir(v.vertex);//世界空间 光方向
				f.worldPos = UnityObjectToWorldDir(v.vertex);//世界空间 顶点坐标
				return f;
			}

			fixed4 frag (v2f f ) : SV_TARGET0{
				fixed3 worldNormal = normalize(f.worldNormal);
				fixed3 worldLight = normalize(f.worldLight);

				fixed3 albeodVal = tex2D(_MainTex, f.uv).rgb * _Color.rgb;//采样纹理乘自定义漫反射颜色强度 计出  反照率

				fixed3 ambientVal = UNITY_LIGHTMODEL_AMBIENT.xyz * albeodVal;//环境光 

				fixed3 diffuseVal = _LightColor0.rgb * albeodVal.rgb * saturate(dot(worldNormal, worldLight));

				fixed3 viewDirVal = normalize(UnityWorldSpaceViewDir(f.worldPos));//世界空间 视角方向
				fixed3 halfDir = normalize(worldLight + viewDirVal);
				fixed3 specularVal = _LightColor0.rgb * _Specular.rgb * pow(saturate(dot(worldNormal, halfDir)), _Gloss);

				return fixed4(ambientVal + diffuseVal + specularVal, 1.0);
			}

			ENDCG
		}
	}

	FallBack "Specular"

}


