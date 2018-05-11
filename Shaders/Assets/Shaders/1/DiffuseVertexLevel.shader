/****
这是一个逐顶点光照着色器。顶点着色器的最基本任务就是把顶点位置从模型空间转换到裁剪空间。
思路：
计算漫反射所需：（兰伯特模型）
1：入射光源颜色与强度。_LightColor0.rgb,需要标签Tags中定义的LightMode=ForwardBase，并引入Unity文件"Lighting.cginc"。
2：自定义漫反射颜色与强度。
3：世界坐标系下，模型法线的单位向量。通过内置函数 UnityObjectToWorldNormal(模型法线) 来转换获得
4：世界坐标系下，入射光源的单位向量。_WorldSpaceLightPos0.rgb。
公式：1*2*dot(3,4)。注意在确保点积后的值不有少于0，否则光线就是从背面照过来，这样是不合理的，所以要用
	  saturate来限制不小于0。
****/

//定义这个Shader的路径与名称。
Shader "Learn/1/DiffuseVertexLevel" {
	//Properties声明中的类型各类有8种：int,float,range(min,max),color,vector,2D,cube,3D。
	//在属性语义中声明一个Color类型的属性，给面板上编辑。
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
			//颜色属性的范围在0~1之间，因此使用fixed精度就满足。
			fixed4 _Diffuse;

			//对于输入属性的名称，不要做修改,例如normal,tangent，不要加_号。因为例如切线空间下的宏定义，改了名会报错。
			struct a2v {
				float4 vertex : POSITION;
				float3 normal : NORMAL;
			};
			
			struct v2f {
				float4 clipPos : SV_POSITION;
				fixed3 color : COLOR;
			};

			v2f vert (a2v v ) {
				v2f f;
				//将模型顶点从模型坐标系，转换到裁剪坐标系。即UNITY_MATRIX_MVP 矩阵。
				f.clipPos = UnityObjectToClipPos(v.vertex);
				//获取世界坐标系下的单位法线向量
				fixed3 _worldNormal = normalize(UnityObjectToWorldNormal(v.normal));
				//获取世界坐标系下的单位入射光向量。不具通用性，这是假设场景中只有一个平行光源。
				fixed3 _worldLight = normalize(_WorldSpaceLightPos0.xyz);
				//计算漫反射:入射光颜色强度c * 自定义漫反射颜色强度d * （世界坐标下，单位法向量与入射光单位向量的点积）v，注意v不能为负，因此用saturate截取到小于0，等于0;
				fixed3 _diffuseVal = _LightColor0.rgb * _Diffuse.rgb * saturate(dot(_worldNormal, _worldLight));
				//环境光
				fixed3 _ambientVal = UNITY_LIGHTMODEL_AMBIENT.xyz;

				f.color = _ambientVal + _diffuseVal;

				return f;
			}

			fixed4 frag(v2f f ) : SV_TARGET0{
				return fixed4(f.color, 1.0);
			}

			ENDCG
		}
	}

	FallBack "Diffuse"

}







