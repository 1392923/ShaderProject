﻿/****
这是一个逐像素光照着色器。
思路：
计算漫反射所需：(兰伯特模型)
1：入射光源颜色与强度。_LightColor0.rgb,需要标签Tags中定义的LightMode=ForwardBase，并引入Unity文件"Lighting.cginc"。
2：自定义漫反射颜色与强度。
3：世界坐标系下，模型法线的单位向量。通过内置函数 UnityObjectToWorldNormal(模型法线) 来转换获得
4：世界坐标系下，入射光源的单位向量。_WorldSpaceLightPos0.rgb。
公式：1*2*dot(3,4)。注意在确保点积后的值不有少于0，否则光线就是从背面照过来，这样是不合理的，所以要用
	  saturate来限制不小于0。
****/

Shader "Learn/1/DiffusePixeLevel" {

	Properties{
		_Diffuse("Diffuse", COLOR) = (1,1,1,1)
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

			v2f vert(a2v v ){
				v2f f;
				//顶点，从模型空间转换到裁剪空间。
				f.clipPos = UnityObjectToClipPos(v.vertex);
				//法线，从模型空间转换到世界空间。
				f.worldNormal = UnityObjectToWorldNormal(v.normal);
				return f;
			}

			fixed4 frag(v2f f) : SV_TARGET0{
				fixed3 _worldNormal = normalize(f.worldNormal);
				//计算漫反射:入射光颜色强度c * 自定义漫反射颜色强度d * （世界坐标下，单位法向量与入射光单位向量的点积）v，注意v不能为负，因此用saturate截取到小于0，等于0;
				fixed3 _worldLight = normalize(_WorldSpaceLightPos0.xyz);
				//兰伯特计算模型。
				fixed3 _diffuseVal = _LightColor0.rgb * _Diffuse.rgb * saturate(dot(_worldNormal, _worldLight));
				//环境光
				fixed3 _ambientVal = UNITY_LIGHTMODEL_AMBIENT.xyz;

				return fixed4(_ambientVal + _diffuseVal, 1.0);
			}

			ENDCG
		}
	}
	//FallBack 很重要，不是随便乱写的，会影响光影等。
	FallBack "Diffuse"

}