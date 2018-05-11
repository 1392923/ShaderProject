/*****
凹凸映射(bump mapping)
作用：
使用一张纹理来修改模型表面的法线，以便为模型提供更多的细节。这种方法不会真的改变模型的顶点位置，只是让模型看起来像是凹凸不平。
实现方法：
1：使用一张高度纹理(height map)来模拟表面位移(displacement),然后得到一个修改后的法线值。这种方法叫——高度映射(height mapping)。
2：使用一张法线纹理(normal map)来直接存储表面法线，这种方法叫——法线映射(normal mapping)。(常用选择)

******/

Shader "Learn/2/BumpMapping" {
	//属性类型有8种：int, float, color, vector ,range(min,max), 2D, 3D, Cube
	Properties {
		_Color("Color", COLOR) = (1,1,1,1)
		_MainTex("MainTex",2D) = "while" {}
		_BumpMap("BumpMap", 2D) = "bump" {}
		_BumpScale("BumpScale", Range(0.1, 2)) = 1
		_Specular("Specular", COLOR) = (1,1,1,1)
		_Gloss("Gloss", Range(1, 256)) = 20
	}

	SubShader{
		Tags{"LightMode"="ForwardBase"}
		Pass{
			CGPROGRAM
			#pragma vertex vert 
			#pragma fragment frag

			#include "Lighting.cginc"

			float4 _Color;
			sampler2D _MainTex;
			float4 _MainTex_ST;
			sampler2D _BumpMap;
			float4 _BumpMap_ST;
			fixed _BumpScale;
			float4 _Specular;
			float _Gloss;

			struct a2v {
				float4 vertex : POSITION;
				float3 normal : NORMAL;
				float4 tangent : TANGENT;
				float4 texcoord : TEXCOORD0;
			};

			struct v2f {
				float4 clipPos : SV_POSITION;
				float4 uv : TEXCOORD0;
				float3 tangentLightDir : TEXCOORD1;
				float3 tangentViewDir : TEXCOORD2;
			};

			v2f vert(a2v v) {
				v2f f;
				f.clipPos = UnityObjectToClipPos(v.vertex);
				f.uv.xy = TRANSFORM_TEX(v.texcoord, _MainTex);
				f.uv.zw = TRANSFORM_TEX(v.texcoord, _BumpMap);
				
				//TANGENT_SPACE_ROTATION , 此宏定义在(UnityCG.cginc)。
				//使用此宏要注意，在数据结构a2v中，被定义的属性必须包含有，'normal' 'tangent'，且名称不能被修改。
				//此宏 == 以下计算。
				//float3 binormal = cross(normalize(v.normal), normalize(v.tangent.xyz)) * v.tangent.w;
				//float3X3 rotation = float3X3(v.tangent.xyz, binormal, v.normal);
				TANGENT_SPACE_ROTATION;
				f.tangentLightDir = mul(rotation, ObjSpaceLightDir(v.vertex)).xyz;//切线空间下的光线方向
				f.tangentViewDir = mul(rotation, ObjSpaceViewDir(v.vertex)).xyz;//切线空间下的视角方向

				return f;
			}

			fixed4 frag(v2f f ) : SV_TARGET0{
				fixed3 tangentLightDir = normalize(f.tangentLightDir);
				fixed3 tangentViewDir = normalize(f.tangentViewDir);
				//纹理采样
				fixed4 packedNormal = tex2D(_BumpMap, f.uv.zw);
				//如果法线纹理类型没有设置成Norml map，需要进行以下反映射。求得切线空间下的法线向量。
				fixed3 tangentNormal = UnpackNormal(packedNormal);
				tangentNormal.xy *= _BumpScale;
				tangentNormal.z = sqrt(1.0 - saturate(dot(tangentNormal.xy, tangentNormal.xy)));

				fixed3 albedoVal = tex2D(_MainTex, f.uv.xy).rgb * _Color.rgb; 
				fixed3 ambientVal = UNITY_LIGHTMODEL_AMBIENT.xyz * albedoVal;

				fixed3 diffuseVal = _LightColor0.rgb * albedoVal.rgb * saturate(dot(tangentNormal, tangentLightDir));
				
				fixed3 halfDirVal = normalize(tangentLightDir + tangentViewDir);
				fixed3 specularVal = _LightColor0.rgb * _Specular.rgb * pow(saturate(dot(tangentNormal, halfDirVal)), _Gloss);

				return fixed4(ambientVal + diffuseVal + specularVal,1);
			}
			ENDCG
		}
	}

	FallBack "Specular"

}