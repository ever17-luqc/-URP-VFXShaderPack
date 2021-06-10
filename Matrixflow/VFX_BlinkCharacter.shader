Shader "VFX/BlinkCharacter"
{
    Properties
    {   
        [HDR]_MainCol("_MainCol",Color)=(1,1,1)
        _UniformTiling("Uniform Tiling",Float)=1
        [NoScaleOffset]_RandomTex("Random Tex",2D)="white"{}
        _RandomTexPerTexel("Random Tex Texel Count",Float )=256
        _RandomSpeed("Random Flow Speed",Float)=0.5
        [NoScaleOffset]_CharacterTex ("Character Texture", 2D) = "white" {}
        _CharacterTexPerTexel("Character Tex Texel Count",Float)=256
        _CharacterFrequency("Character Frequency",Float)=0.5
        _CharacterCountPerGroup("Character Count Per Group",Float)=5
        _CharacterLuminaceOffset("Character Luminance Offset",Float)=2
        [NoScaleOffset]_MaskTex("Mask Tex",2D)="white"{}
        _MaskTexPerPixel("Mask Tex Texel Count",float)=256
        _MaskStr("Mask Str",Range(0,1))=1
        [NoScaleOffset]_OffsetMask("Offset Mask",2D)="white" {}
        _OffsetTexPerTexel("Offset Tex Texel Count",Float)=256
        _OffsetSpeedFactor("Offset Speed Factor",Float)=1
        _OffsetStr("Offset Tex Strength",Range(0,2))=1

    }
    SubShader
    {
        Tags { "RenderType"="Opaque" }
        LOD 100

        Pass
        {
            HLSLPROGRAM
            #pragma vertex vert
            #pragma fragment frag
            

            #include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/Lighting.hlsl"

            struct appdata
            {
                float4 vertex : POSITION;
                float2 uv : TEXCOORD0;
            };

            struct v2f
            {
                float2 uv : TEXCOORD0;
                
                float4 vertex : SV_POSITION;
            };

            CBUFFER_START(UnityPerMaterial)
            half _UniformTiling;
            float _RandomTexPerTexel;
            float _CharacterTexPerTexel;
            half _CharacterFrequency;
            float _RandomSpeed;
            half _CharacterCountPerGroup;
            half _CharacterLuminaceOffset;
            float _MaskTexPerPixel;
            float _MaskStr;
            half3 _MainCol;
            float _OffsetTexPerTexel;
            float _OffsetSpeedFactor;
            half _OffsetStr;
            CBUFFER_END
            TEXTURE2D(_RandomTex);    SAMPLER(sampler_RandomTex);
            TEXTURE2D(_CharacterTex); SAMPLER(sampler_CharacterTex);
            TEXTURE2D(_MaskTex);      SAMPLER(sampler_MaskTex);
            TEXTURE2D(_OffsetMask);   SAMPLER(sampler_OffsetMask);

            v2f vert (appdata v)
            {
                v2f o;
                o.vertex = TransformObjectToHClip(v.vertex);
                o.uv = v.uv;
                
                return o;
            }

            half4 frag (v2f i) : SV_Target
            {
                float2 Uv_Uniform=i.uv*_UniformTiling;
                half randomSpeed=SAMPLE_TEXTURE2D(_RandomTex,sampler_RandomTex,Uv_Uniform.xx/_RandomTexPerTexel).r*3-2;//Y方向 横坐标相同的点流动速度相同
                float YSpeed_Random=_Time.y*randomSpeed*_RandomSpeed;   //Y方向流速
                half2 randomCharacter_ID=SAMPLE_TEXTURE2D(_RandomTex,sampler_RandomTex,Uv_Uniform/_RandomTexPerTexel+float2(round(_Time.y*_CharacterFrequency*randomSpeed),frac(YSpeed_Random))/_RandomTexPerTexel).xy;
                randomCharacter_ID=round(randomCharacter_ID*_CharacterCountPerGroup)/_CharacterCountPerGroup;
                half4 Character = SAMPLE_TEXTURE2D_LOD(_CharacterTex,sampler_CharacterTex,Uv_Uniform/_CharacterCountPerGroup+randomCharacter_ID+float2(0,frac(YSpeed_Random))/_CharacterCountPerGroup,0);//字体
                Character*=randomCharacter_ID.r*_CharacterLuminaceOffset-(_CharacterLuminaceOffset-1);
                Character.rgb*=_MainCol;
                half MaskValue=lerp(0,SAMPLE_TEXTURE2D(_MaskTex,sampler_MaskTex,round(i.uv*_UniformTiling)/_UniformTiling),_MaskStr);//遮罩
                half OffsetMask=SAMPLE_TEXTURE2D(_OffsetMask,sampler_OffsetMask,(Uv_Uniform+float2(0,YSpeed_Random*_OffsetSpeedFactor))/_OffsetTexPerTexel).r*_OffsetStr-(_OffsetStr-1);
                return Character*MaskValue*OffsetMask;
            }
            ENDHLSL
        }
    }
}
