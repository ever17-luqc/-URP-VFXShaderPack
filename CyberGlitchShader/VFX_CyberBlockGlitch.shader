Shader "VFX Effects/VFX_CyberBlockGlitch"
{
    Properties
    {   [Enum(Blend,5,ADD,1)]_BlendSrc("源混合因子",Float)=5
        [Enum(Blend,10,ADD,1)]_BlendDst("目标混合因子",Float)=10
       
        [HDR]_MainColor("主贴图颜色",Color)=(1,1,1,1)
        [NoScaleOffset]_MainTex ("主贴图", 2D) = "white" {}
        
         _Frequency("图案频率",Int)=15
         
         _RandomSpeed("随机马赛克速度",Float)=2
         _RandomClipStr("随机裁剪度",Range(0,1))=0.6
         _RandomSpeed2("随机马赛克速度2",Float)=3
         _Frequency2("碎片频率(xy)",vector)=(25,20,0,0)
         _RandomClipStr2("碎片随机裁剪度2",Range(0,1))=0.5
         _RandomOffset("切片偏移打乱颜色(xy)",vector)=(0,0,0,0)
         [Space(10)]
         [NoScaleOffset]_Rampmap("Rampmap",2D) = "white" {}
         _ColorOffsetMain("图案颜色随机位置",Int)=5
         _ColorBlinkSpeedMain("图案颜色随机速度",Float)=1
     
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
           
            half4 _MainColor;
            uint _Frequency;
            
            float _RandomSpeed;
            float _RandomClipStr;
            float _RandomSpeed2;
            float2 _Frequency2;
            float _RandomClipStr2;
            float2 _RandomOffset;

            uint _ColorOffsetMain;
            float _ColorBlinkSpeedMain;
           
            CBUFFER_END

            TEXTURE2D(_MainTex);          SAMPLER(sampler_MainTex);
          
            TEXTURE2D(_Mask);             SAMPLER(sampler_Mask);
            TEXTURE2D(_Rampmap);          SAMPLER(sampler_Rampmap);
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
               
                o.uv.xy=v.uv.xy*_Frequency;
                o.uv.zw= v.uv.xy;
                
                return o;
            }
        
            half4 frag (v2f i) : SV_Target
            {   
                half randomNoise=hash12_withoutSine(floor(i.uv.xy),_Time.y*_RandomSpeed);
                half randomNoise_RampMain=hash12_withoutSine(floor(i.uv.xy+_ColorOffsetMain),_Time.y*_ColorBlinkSpeedMain);
                
                

                float4  mainRamp=SAMPLE_TEXTURE2D(_Rampmap,sampler_Rampmap,float2(floor(randomNoise_RampMain*2)/2,0));
                float4 mainCol=SAMPLE_TEXTURE2D(_MainTex,sampler_MainTex,i.uv.xy)*_MainColor*mainRamp;
                
                //Clip
                half randomNoise2=hash12_withoutSine(floor(i.uv.zw*_Frequency2),_Time.y*_RandomSpeed2);
                 half randomNoise_Offset=hash12_withoutSine(floor(i.uv.xy+_RandomOffset),_Time.y*_RandomSpeed);
                half BlockMask=step(randomNoise-_RandomClipStr,0);
                //half InverseBlockMask=1-BlockMask;
                 clip(lerp(randomNoise-_RandomClipStr,randomNoise2*randomNoise-_RandomClipStr2,BlockMask));
                //return randomNoise2;

                float4 subRamp=SAMPLE_TEXTURE2D(_Rampmap,sampler_Rampmap,float2(randomNoise2*randomNoise_Offset,0));
               
                float4 Mask=SAMPLE_TEXTURE2D(_Mask,sampler_Mask,i.uv.zw);
                mainCol.a*=pow(randomNoise,4);
                mainCol=lerp(mainCol,subRamp,BlockMask);
                

                
                return mainCol;
            }
            ENDHLSL
        }
    }
}
