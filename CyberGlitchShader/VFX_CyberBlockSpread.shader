Shader "VFX Effects/VFX_CyberBlockSpread"
{
    Properties
    {   [Enum(Blend,5,ADD,1)]_BlendSrc("源混合因子",Float)=5
        [Enum(Blend,10,ADD,1)]_BlendDst("目标混合因子",Float)=10
        [HDR]_MainColor("主贴图颜色",Color)=(1,1,1,1)
        [NoScaleOffset]_MainTex ("主贴图", 2D) = "white" {}
        _NxN("图案行列个数",Int)=1
        _PatternSpeed("图案变化速度",Float)=0
        _Frequency("图案频率",Int)=15
        [NoScaleOffset]_ClipMask("扩散裁剪(溶解)贴图",2D)="white"{}
        _Spread("扩散",Range(0,2))=0
        _ClipThreshold("裁剪度",Range(0,1))=0
        _Pixel("贴图分辨率",Float)=256
        _Density("随机马赛克剔除密度",Range(0,1))=0
        _Size("随机马赛克剔除大小",Float)=1
        _RandomSpeed("随机马赛克剔除速度",Float)=1
        [Header(Mask)]
        [NoScaleOffset]_Mask("遮罩",2D)="white"{}
    }
    SubShader
    {
        
        Tags {  "RenderType"="Transparent" "RenderPipeline" = "UniversalPipeline" "LightMode" =  "UniversalForward" "Queue"="Transparent"}
        LOD 100
        Zwrite Off
        Blend [_BlendSrc][_BlendDst]

        Pass
        {
            HLSLPROGRAM
            #pragma vertex vert
            #pragma fragment frag


            #include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/Core.hlsl"

            struct appdata
            {
                float4 vertex : POSITION;
                float2 uv : TEXCOORD0;
            };

            struct v2f
            {
                float4 uv : TEXCOORD0;

                float4 vertex : SV_POSITION;
            };
            CBUFFER_START(UnityPerMaterial)
           
            uint  _NxN;
            half4 _MainColor;
            uint _Frequency;
            half _Spread;
            half _ClipThreshold;
            float _Pixel;
            half _Density;
            float _RandomSpeed;
            float _PatternSpeed;
            uint _Size;
            CBUFFER_END

            TEXTURE2D(_MainTex);          SAMPLER(sampler_MainTex);
            TEXTURE2D(_ClipMask);         SAMPLER(sampler_ClipMask);
            TEXTURE2D(_Mask);             SAMPLER(sampler_Mask);
            
            float hash12(float2 coord,float time)
            {
                float noise=frac( sin( dot(coord*floor(time),float2(12.9898, 78.233) ) )*43758.5453 );
                return noise;
            }
            float hash12_withoutSine(float2 p,float time)
            {
	        float3 p3  = frac(float3(p.xyx) * .1031*floor(time));
            p3 += dot(p3, p3.yzx + 33.33);
            return frac((p3.x + p3.y) * p3.z);
            }

            v2f vert (appdata v)
            {
                v2f o;
                o.vertex = TransformObjectToHClip(v.vertex);
               
               //o.uv.xy=v.uv.xy*_Frequency*(2-_Spread)+(0.5-0.5*(2-_Spread))*_Frequency;
                o.uv.xy=_Frequency*(v.uv.xy*_Spread+(0.5-0.5*_Spread));
                o.uv.zw= v.uv.xy;
                
                return o;
            }
        
            half4 frag (v2f i) : SV_Target
            {   
                
                half randomNoise2=hash12_withoutSine(floor(i.uv.xy),_Time.y*_PatternSpeed);
                
                half randomNoise=hash12_withoutSine(floor(i.uv.xy/_Size),_Time.y*_RandomSpeed);
               
               
                uint row=floor(randomNoise2*_NxN);
                uint column=max(floor(randomNoise2*_NxN*_NxN)-floor(randomNoise2*_NxN)*_NxN,0);
                //return half4(column,row,1,1);
                 float2 uv_main=float2(i.uv.xy+float2(column,row))/_NxN;
                // half Pixel=_Pixel*2;
                // half dx_main=clamp(ddx(uv_main),-1/Pixel,1/Pixel);
                // half dy_main=clamp(ddy(uv_main),-1/Pixel,1/Pixel);
                half4 col = SAMPLE_TEXTURE2D(_MainTex, sampler_MainTex,uv_main)*_MainColor;
                //half4 col = SAMPLE_TEXTURE2D_GRAD(_MainTex, sampler_MainTex,uv_main,dx_main,dy_main)*_MainColor;

                
               
                float2 uvClip=floor(i.uv.xy)/(_Frequency);
               
                
                // half dx=clamp(ddx(uvClip),-1/Pixel,1/Pixel);
                // half dy=clamp(ddy(uvClip),-1/Pixel,1/Pixel);
                half4 ClipMask=SAMPLE_TEXTURE2D(_ClipMask,sampler_ClipMask,uvClip);
                //half4 ClipMask=SAMPLE_TEXTURE2D_GRAD(_ClipMask,sampler_ClipMask,uvClip,dx,dy);
                clip(ClipMask.r-_ClipThreshold-0.01-lerp(0,randomNoise,_Density));
                //return ClipMask;
                //return randomNoise;

                //Mask
                float4 Mask=SAMPLE_TEXTURE2D(_Mask,sampler_Mask,i.uv.zw);
                return col*Mask;
            }
            ENDHLSL
        }
    }
}
