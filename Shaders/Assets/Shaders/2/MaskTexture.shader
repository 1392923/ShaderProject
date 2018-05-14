/******
遮罩纹理(mask texture)
作用:可以让美术人员更加精准(像素级别)地控制模型表面的各种性质。
1：允许我们可以保护某些区域，使它们免于某些修改。例如有时我们希望模型表面某些区域的反光强烈些，而某些区域弱一些，为了得到更加细腻的效果，我们就可以使用一张遮罩纹理来控制光照。
2：在制作地表材质时需要混合多张图片，例如表现草地的纹理、表现石子的纹理、表现祼露土地的纹理等，使用遮罩纹理可以控制如何混合这些纹理。
思路流程：
通过采样得到遮罩纹理的纹素值，然后使用其中某个(或某几个)通道的值(例如texel.r)来与某种表面属性进行相乘，这样当该通道为0时，可以保护表面不受属性的影响。


******/

Shader "Learn/2/MaskTexture" {

	Properties{
		_Diffuse("Diffuse",COLOR) = (1,1,1,1)
		_MainTex("MainTex", 2D) = "while" {}
		_BumpMap("BumpMap",2D) = "bump" {}
		_BumpScale("BumpScale",Range(0.1, 2)) = 1
		_SpecularMask("SpecularMask", 2D) = "while" {}
		_SpecularMaskScale("SpecularMaskScale", Range(0.1,2)) = 1
		_Specular("Specular",COLOR) = (1,1,1,1)
		_Gloss("Gloss", Range(8.0,256)) = 20
	}

	SubShader{
		Pass{
			Tags{"LightMode" = "ForwardBase"}
			CGPROGRAM
			#pragma vertex vert 
			#pragma fragment frag 
			#include "Lighting.cginc"

			float4 _Diffuse;
			sampler2D _MainTex;
			float4 _MainTex_ST;
			sampler2D _BumpMap;
			fixed _BumpScale;
			sampler2D _SpecularMask;
			fixed _SpecularMaskScale;
			float4 _Specular;
			float _Gloss;

			struct a2v {
				float4 vertex : POSITION;
				float3 normal : NORMAL;
				float4 tangent : TANGENT;
				float4 texcoord : TEXCOORD;
			};

			struct v2f {
				float4 pos : SV_POSITION;
				float2 uv : TEXCOORD0;
				float3 lightDir : TEXCOORD1;//切线空间下的光照方向。
				float3 viewDir : TEXCOORD2;//切线空间下的视角方向。
			};

			v2f vert(a2v v) {
				v2f f;
				f.pos = UnityObjectToClipPos(v.vertex);
				f.uv = TRANSFORM_TEX(v.texcoord, _MainTex);

				TANGENT_SPACE_ROTATION;//切线空间旋转矩阵
				//不能拆出来写。。与上面的宏定义要连着定，否则报错。
				//float3 lightDirVal = ObjSpaceLightDir(v.vertex);//模型空间下，该顶点到光源的方向。
				//float viewDirVal = ObjSpaceViewDir(v.vertex);//模型空间下，该顶点到摄像机的视角方向。
				f.lightDir = mul(rotation, ObjSpaceLightDir(v.vertex)).xyz;
				f.viewDir = mul(rotation, ObjSpaceViewDir(v.vertex)).xyz;

				return f;
			}

			fixed4 frag(v2f f) : SV_TARGET0{
				fixed3 tangentLightDir = normalize(f.lightDir);
				fixed3 tangentViewDir = normalize(f.viewDir);

				float4 bumpTex = tex2D(_BumpMap, f.uv);
				fixed3 tangentNormal = UnpackNormal(bumpTex);
				tangentNormal.xy *= _BumpScale;
				float m = dot(tangentNormal.xy, tangentNormal.xy);//dot自己，求得模长的平方。
				tangentNormal.z = sqrt(1.0 - saturate(m));

				fixed3 albedoVal = tex2D(_MainTex, f.uv).rgb * _Diffuse.rgb;
				fixed3 ambientVal = UNITY_LIGHTMODEL_AMBIENT.xyz * albedoVal;

				fixed diffuseVal = _LightColor0.rgb * albedoVal.rgb * saturate(dot(tangentNormal, tangentLightDir));

				fixed3 halfDir = normalize(tangentLightDir + tangentViewDir);
				fixed specularMaskVal = tex2D(_SpecularMask, f.uv).r * _SpecularMaskScale;

				fixed specularVal = _LightColor0.rgb * _Specular.rgb * pow(saturate(dot(tangentNormal, halfDir)), _Gloss) * specularMaskVal;

				return fixed4(ambientVal + diffuseVal + specularVal,1.0);
			}

			ENDCG
		}
	
	}

	FallBack "Specular"
}