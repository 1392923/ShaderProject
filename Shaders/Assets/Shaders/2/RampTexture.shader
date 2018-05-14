/******
渐变纹理，控制漫反射光照的结果。
实现思路：通过世界空间下的法线与入射光的点积，用半兰伯特算法得到[0,1]的映射值。并用此值作为纹理坐标，对渐变纹理进行采样。由于渐变纹理实际上是一个一维纹理(他的纵轴y方向上的颜色不变)，因此纹理坐标u和v方向同用此值。最后把采样的颜色和材质颜色相乘，得到漫反射颜色。
需要注意：使用渐变纹理，纹理的Wrap Mode要设为 Clamp。否则会出现，由浮点精度造成的黑点等问题。
*******/

Shader "Learn/2/RampTextrue" {

	Properties{
		_Diffuse("Diffuse", COLOR) = (1,1,1,1)
		_RampTex("RampTex", 2D) = "while" {}
		_Specular("Specular", COLOR) = (1,1,1,1)
		_Gloss("Gloss", Range(1,256)) = 20
	}

	SubShader{
		Pass{
			Tags{"LightMode"="ForwardBase"}
			CGPROGRAM
			#pragma vertex vert 
			#pragma fragment frag 

			#include "Lighting.cginc"

			float4 _Diffuse;
			sampler2D _RampTex;
			float4 _RampTex_ST;
			float4 _Specular;
			float _Gloss;

			struct a2v {
				float4 vertex : POSITION;
				float3 normal : NORMAL;
				float4 texcoord : TEXCOORD0;
			};

			struct v2f {
				float4 clipPos : SV_POSITION;
				float3 worldNormal : TEXCOORD0;
				float3 worldPos : TEXCOORD1;
				float2 uv : TEXCOORD2;
			};

			v2f vert(a2v v) {
				v2f f;
				f.clipPos = UnityObjectToClipPos(v.vertex);
				f.worldNormal = UnityObjectToWorldNormal(v.normal);
				f.worldPos = UnityObjectToWorldDir(v.vertex);
				f.uv = TRANSFORM_TEX(v.texcoord, _RampTex);
				return f;
			}

			fixed4 frag(v2f f) : SV_TARGET0{
				fixed3 worldNormal = normalize(f.worldNormal);
				fixed3 worldLightDir= normalize(UnityWorldSpaceLightDir(f.worldPos));

				fixed halfLbt = dot(worldNormal, worldLightDir) * 0.5 + 0.5;
				fixed3 diffuseColor = tex2D(_RampTex, fixed2(halfLbt, halfLbt)).rgb * _Diffuse.rgb;

				fixed3 diffuseVal = _LightColor0.rgb * diffuseColor;

				fixed3 viewDir = normalize(UnityWorldSpaceViewDir(f.worldPos));
				fixed3 halfDir = normalize(worldLightDir + viewDir);
				fixed3 specularVal = _LightColor0.rgb * _Specular.rgb * pow(saturate(dot(worldNormal, halfDir)), _Gloss);

				fixed3 ambientVal = UNITY_LIGHTMODEL_AMBIENT.xyz;

				return fixed4(ambientVal + diffuseVal + specularVal, 1.0);
			}

			ENDCG
		}
	}

	FallBack "Specular"
}