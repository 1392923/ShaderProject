// Upgrade NOTE: replaced '_Object2World' with 'unity_ObjectToWorld'

/******
透明效果
要实现透明效果，通常会在渲染模型时控制它的透明通道(Alpha Channel)。当开启透明混合后，一个物体被渲染到屏幕上时，每个片元除了颜色和深度值外，还有一个透明度 属性。当透明度为1时，该像素完全不透明; 当值为0时，该像素完全透明，不会显示。
在unity中通常使用两种方法来实现透明效果：1.透明度测试(Alpha Test);2.透明度混合(Alpha Blending)。
强大的深度缓冲技术(depth buffer / z-buffer)，可以让我们不用关心不透明物体的渲染顺序。
当使用透明度混合时，我们要关闭了深度写入(ZWrite)。事情就变得复杂了。
透明度测试原理：它采用一种“霸道极端”的机制，只要一个片元的透明度不满足条件(通常是小于某个阈值)，那么它对应的片元就会被舍弃，不做任何处理，不会对颜色缓冲产生影响。否则，就会按照普通的不透明物体处理，进行深度测试、深度写入等。也就是说，透明度测试是不需要关闭深度写入的，它和其他不透明物体最大的不同就是它会根据透明度来舍弃一些片元。虽然简单，但也极端，要么完全透明看不到，要么完全不透明可见。当开启透明混合后，一个物体被渲染到屏幕上时，每个片元除了颜色和深度值外，还有一个透明度可见。
透明度混合原理：可得到真正的半透明效果。它会使用当前片元的透明度作为混合因子，与已经存储在颜色缓冲中的颜色值进行混合，得到新的颜色。但是，透明度混合需要关闭深度写入，这使得我们要非常小心物体的渲染顺序。注意，透明度混合只关闭了深度写入，但没有关闭深度测试。这意味首，当使用透明度混合渲染一个片元时，还是会比较它的深度值与当前深度缓冲中的深度值，如果它的深度值距离摄像机更远，那么就不会再进行混合操作。这一点决定了，当一个不透明物体出现在一个透明物体的前面，而我们先渲染了不透明物体，它仍然可以正常地遮挡住透明物体。也就是说，对于透明度混合来说，深度缓冲是只读的。

******/
/***
透明度测试
处理透明度测试，实际上跟对待普通的不透明物体是几乎一样的，只是在片元着色器中增加了对透明度判断并裁剪片元的代码。
利用 clip(float f) 函数，判断传入的值f是否小于0。如果是则裁剪，不往下执行，否则继续往下执行渲染流程。
注意FallBack
***/
Shader "Learn/3/AlphaTest" {

	Properties{
		_Color("Color Tint", COLOR) = (1,1,1,1)
		_MainTex("Main Tex", 2D) = "while" {}
		_Cutoff("Cutoff", Range(0, 1)) = 1
	}

	SubShader{
		Tags{"Queue"="AlphaTest" "IgnoreProjector"="true" "RenderType"="TransparentCutout"}
		Pass{
			Tags{"LightMode"="ForwardBase"}
			CGPROGRAM
			#pragma vertex vert 
			#pragma fragment frag 
			#include "Lighting.cginc"

			float4 _Color;
			sampler2D _MainTex;
			float4 _MainTex_ST;
			fixed _Cutoff;

			struct a2v {
				float4 vertex :POSITION;
				float3 normal : NORMAL;
				float4 texcoord : TEXCOORD0;
			};

			struct v2f {
				float4 pos : SV_POSITION;
				float3 worldNormal : TEXCOORD0;
				float4 worldPos : TEXCOORD1;
				float2 uv : TEXCOORD2;
			};

			v2f vert(a2v v){
				v2f f;
				f.pos = UnityObjectToClipPos(v.vertex);
				f.worldNormal = UnityObjectToWorldNormal(v.normal);
				f.worldPos = mul(unity_ObjectToWorld, v.vertex);
				f.uv = TRANSFORM_TEX(v.texcoord, _MainTex);
				return f;
			}

			fixed4 frag(v2f f) : SV_TARGET0{
				float4 texColor = tex2D(_MainTex, f.uv);
				clip(texColor.a - _Cutoff);//透明度测试，即如果传入的值少于0，则不往下执行。

				fixed3 worldNormal = normalize(f.worldNormal);
				fixed3 worldLightDir = UnityWorldSpaceLightDir(f.worldPos);

				fixed3 albedo = texColor.rgb * _Color.rgb;//反照率
				fixed3 ambient = UNITY_LIGHTMODEL_AMBIENT.rgb * albedo;

				fixed3 diffuse = _LightColor0.rgb * albedo * saturate(dot(worldNormal, worldLightDir));

				return fixed4(ambient + diffuse, 1.0);
			}


			ENDCG
		}
	}
	//注意回调 
	FallBack "Transparent/Cutout/VertexLit"

}
