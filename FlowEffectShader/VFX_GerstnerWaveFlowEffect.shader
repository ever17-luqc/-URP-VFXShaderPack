Shader "VFX Effects/VFX_GerstnerWaveFlowEffect"
{
    Properties
    {   [HDR] _Color("_MainCol",Color)=(1,1,1)
        _MainTex ("Texture", 2D) = "white" {}
        _MainTexSpeedXY("Maintex Speed XY",Vector)=(0,0,0,0)
        [Header(Wave Global)]
        _NormalTrend("倾向法线方向",Range(0,1))=0
        _NormalDirStr("法线方向强度",Range(0,1))=0.1
        [Header(Wave 1)]
        _D1("Wave1 方向",Vector)=(1,0,0,0)
        _W1("Wave1 频率",Float)=0.07
        _Q1("Wave1 陡度",Float)=0.2
        _A1("Wave1 波峰高度",Float)=0.36
        _Phi1("Wave1 相位速度",Float)=0.3

        [Header(Wave 2)]
        _D2("Wave2 方向",Vector)=(0,1,0,0)
        _W2("Wave2 频率",Float)=0.5
        _Q2("Wave2 陡度",Float)=1
        _A2("Wave2 波峰高度",Float)=1
        _Phi2("Wave2 相位速度",Float)=1

        [Header(Wave 3)]
        _D3("Wave3 方向",Vector)=(1,1,0,0)
        _W3("Wave3 频率",Float)=1.2
        _Q3("Wave3 陡度",Float)=0.1
        _A3("Wave3 波峰高度",Float)=0.2
        _Phi3("Wave3 相位速度",Float)=6
        [Header(Mask)]
        _Mask("Mask",2D)="white"{}
        _MaskTexSpeedXY("Mask Speed XY",Vector)=(0,0,0,0)
    }
    SubShader
    {
        Tags {  "RenderType"="Transparent" "RenderPipeline" = "UniversalPipeline" "LightMode" =  "UniversalForward" "Queue"="Transparent"}
        LOD 100
        Zwrite Off
        Blend SrcAlpha OneMinusSrcAlpha

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
                float3 normal:NORMAL;
            };

            struct v2f
            {
                float4 uv : TEXCOORD0;
                float4 vertex : SV_POSITION;
            };


            CBUFFER_START(UnityPerMaterial)
            float4 _Color;
            float4 _MainTex_ST;
            float2 _MainTexSpeedXY;
            float4 _Mask_ST;
            float2 _MaskTexSpeedXY;
            half _NormalTrend;
            half _NormalDirStr;
            float2 _D1;
            float  _W1;
            float  _Q1;
            float  _A1;
            float  _Phi1;
            float2 _D2;
            float  _W2;
            float  _Q2;
            float  _A2;
            float  _Phi2;
            float2 _D3;
            float  _W3;
            float  _Q3;
            float  _A3;
            float  _Phi3;
            CBUFFER_END

            TEXTURE2D(_MainTex);         SAMPLER(sampler_MainTex);
            TEXTURE2D(_Mask);            SAMPLER(sampler_Mask);
           ///////////////////GerstnerWave///////////////////////////
           //         Q*A*Dir.x*cos(dot(w*D,(x,y)+phi*t)
           //
           //P(x,y,t)=A*sin( dot(w*D,(x,y)) +phi*t)
           //
           //         Q*A*Dir.z*cos(dot(w*D,(x,y)+phi*t)
           ///////////////////////////////////////////////////////////
           struct GerstnerWaveData
           {
              float Q;
              float A;
              float W;
              float2 D;
              float Phi;
           };
           void InitGerstnerData(out GerstnerWaveData data,float Q,float A,float W,float2 D,float Phi)
           {
               data.Q=Q;
               data.A=A;
               data.W=W;
               data.D=D;
               data.Phi=Phi;
           }
           float3 GenGerstnerWave(GerstnerWaveData data,float3 vertex)
           {  
               float3 waveVector;
               waveVector.x=data.Q*data.A*data.D.x*(  cos (  dot(data.W*data.D,vertex.xz)     + data.Phi*_Time.y    )    )    ;
               waveVector.z=data.Q*data.A*data.D.y*(  cos (  dot(data.W*data.D,vertex.xz)     + data.Phi*_Time.y    )    )    ;
               waveVector.y=data.A*sin(  dot(data.W*data.D,vertex.xz) +  data.Phi*_Time.y   );
               return waveVector;

           }

            v2f vert (appdata v)
            {
                v2f o;

      
               float3 GerstnerWave1,GerstnerWave2,GerstnerWave3=0;
               GerstnerWaveData data1,data2,data3;
               InitGerstnerData(data1,_Q1,_A1,_W1,_D1,_Phi1);
               InitGerstnerData(data2,_Q2,_A2,_W2,_D2,_Phi2);
               InitGerstnerData(data3,_Q3,_A3,_W3,_D3,_Phi3);
               GerstnerWave1=GenGerstnerWave(data1,v.vertex);
               GerstnerWave2=GenGerstnerWave(data2,v.vertex);
               GerstnerWave3=GenGerstnerWave(data3,v.vertex);

               
                v.vertex.xyz+=(GerstnerWave1+GerstnerWave2+GerstnerWave3)*lerp(1,v.normal*_NormalDirStr,_NormalTrend);
                
                o.vertex = TransformObjectToHClip(v.vertex);
                o.uv.xy = TRANSFORM_TEX(v.uv.xy, _MainTex);
                o.uv.zw = TRANSFORM_TEX(v.uv.xy, _Mask);
                o.uv.xy+=frac(_Time.y*_MainTexSpeedXY);
                o.uv.zw+=frac(_Time.y*_MaskTexSpeedXY);
                return o;
            }

            half4 frag (v2f i) : SV_Target
            {
                //i.uv+=_Time.y*_MainTexSpeedXY;
                half4 col = SAMPLE_TEXTURE2D(_MainTex, sampler_MainTex,i.uv.xy)*_Color;
                half4 Mask=SAMPLE_TEXTURE2D(_Mask,sampler_Mask,i.uv.zw);
                col*=Mask;

                return col;
            }
            ENDHLSL
        }
    }
}
