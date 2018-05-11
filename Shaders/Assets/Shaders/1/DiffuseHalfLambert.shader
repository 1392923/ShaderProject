/****
这是一个逐像素光照着色器。
思路：
计算漫反射所需：(半兰伯特模型)
1：入射光源颜色与强度。_LightColor0.rgb,需要标签Tags中定义的LightMode=ForwardBase，并引入Unity文件"Lighting.cginc"。
2：自定义漫反射颜色与强度。
3：世界坐标系下，模型法线的单位向量。通过内置函数 UnityObjectToWorldNormal(模型法线) 来转换获得
4：世界坐标系下，入射光源的单位向量。_WorldSpaceLightPos0.rgb。
公式：1*2*dot(3,4)。注意在确保点积后的值不有少于0，否则光线就是从背面照过来，这样是不合理的，所以要用
	  saturate来限制不小于0。
****/

Shader "Learn/1/DiffuseHalfLambert" {

	Properties{
		_Diffuse("", COLOR) = (1,1,1,1)
	}

	SubShader{
		Pass{
			Tags{"LightMode"="ForwardBase"}
			CGPROGRAM
			#pragma vertex vert 
			#pragma fragment frag 
			#include "Lighting.cginc"

			fixed4 _Diffuse;

			struct a2v {
				float4 vertex : POSITION;
				float3 normal : NORMAL;
			};

			struct v2f {
				float4 clipPos : SV_POSITION;
				float3 worldNormal : TEXCOORD0;
			};

			v2f vert (a2v v ){
				v2f f;
				f.clipPos = UnityObjectToClipPos(v.vertex);
				//即mul(v._normal, (float3x3)unity_WorldToObject)
				f.worldNormal = UnityObjectToWorldNormal(v.normal);
				return f;
			}

			fixed4 frag(v2f f ) : SV_TARGET0{
				fixed3 _worldNormal = normalize(f.worldNormal);
				fixed3 _worldLight = normalize(_WorldSpaceLightPos0.xyz);
				//半兰伯特计算模型。对其结果进行了一个缩放0.5倍再加上一个0.5大小的位置，从而将结果范围从[-1,1]映射到[0,1]范围内。
				fixed3 _diffuseVal = _LightColor0.rgb * _Diffuse.rgb * (dot(_worldNormal, _worldLight) * 0.5 + 0.5);
				fixed3 _ambientVal = UNITY_LIGHTMODEL_AMBIENT.xyz;
				return fixed4(_ambientVal + _diffuseVal, 1.0);
			}

			ENDCG
		}
	}

	FallBack "Diffuse"
}