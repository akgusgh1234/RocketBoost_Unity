// Unity ShaderLab/HLSL Code
// 이 코드를 "ProceduralSpaceSkybox.shader" 라는 이름의 파일로 저장하세요.
Shader "Skybox/ProceduralSpace"
{
    Properties
    {
        _SkyTint ("Sky Tint", Color) = (.5, .5, .5, 1)
        [Header(Stars)]
        _StarDensity ("Star Density", Range(0.9, 0.999)) = 0.995
        _StarBrightness ("Star Brightness", Range(1, 5)) = 2.0
        [Header(Nebula)]
        _NebulaColor1 ("Nebula Color 1", Color) = (0.8, 0.2, 0.8, 1)
        _NebulaColor2 ("Nebula Color 2", Color) = (0.2, 0.4, 0.9, 1)
        _NebulaScale ("Nebula Scale", Range(0.1, 2)) = 1.0
        _NebulaDensity ("Nebula Density", Range(0, 1)) = 0.5
        _NebulaSpeed ("Nebula Speed", Range(0, 10)) = 2.0
    }
    SubShader
    {
        Tags { "Queue"="Background" "RenderType"="Background" "PreviewType"="Skybox" }
        Cull Off ZWrite Off

        Pass
        {
            CGPROGRAM
            #pragma vertex vert
            #pragma fragment frag

            #include "UnityCG.cginc"

            // Properties에서 선언한 변수들
            fixed4 _SkyTint;
            float _StarDensity;
            float _StarBrightness;
            fixed4 _NebulaColor1;
            fixed4 _NebulaColor2;
            float _NebulaScale;
            float _NebulaDensity;
            float _NebulaSpeed;

            // 2D 랜덤 함수 (해시)
            float rand(float2 st)
            {
                return frac(sin(dot(st.xy, float2(12.9898, 78.233))) * 43758.5453123);
            }
            
            // 2D 노이즈 함수
            float noise(float2 st)
            {
                float2 i = floor(st);
                float2 f = frac(st);

                float a = rand(i);
                float b = rand(i + float2(1.0, 0.0));
                float c = rand(i + float2(0.0, 1.0));
                float d = rand(i + float2(1.0, 1.0));

                float2 u = f * f * (3.0 - 2.0 * f);
                return lerp(a, b, u.x) + (c - a) * u.y * (1.0 - u.x) + (d - b) * u.y * u.x;
            }

            // 프랙탈 노이즈 (FBM - Fractal Brownian Motion)
            float fbm(float2 st)
            {
                float value = 0.0;
                float amplitude = 0.5;
                float frequency = 0.0;
                
                // 4 옥타브(레이어)의 노이즈를 겹쳐서 복잡한 패턴 생성
                for (int i = 0; i < 4; i++)
                {
                    value += amplitude * noise(st);
                    st *= 2.0;
                    amplitude *= 0.5;
                }
                return value;
            }

            struct appdata
            {
                float4 vertex : POSITION;
                float2 uv : TEXCOORD0;
            };

            struct v2f
            {
                float4 vertex : SV_POSITION;
                float3 viewDir : TEXCOORD0;
            };

            v2f vert (appdata v)
            {
                v2f o;
                o.vertex = UnityObjectToClipPos(v.vertex);
                // 카메라에서 픽셀 방향으로의 월드 공간 벡터 계산
                o.viewDir = mul(unity_ObjectToWorld, v.vertex).xyz - _WorldSpaceCameraPos;
                return o;
            }

            fixed4 frag (v2f i) : SV_Target
            {
                // 뷰 방향 벡터 정규화
                float3 dir = normalize(i.viewDir);
                
                // --- 별 생성 ---
                float3 stars_uv = dir * 1000.0; // 별 좌표계 확장
                float star_rand = rand(stars_uv.xy) * rand(stars_uv.yz) * rand(stars_uv.xz);
                float stars = step(_StarDensity, star_rand); // 밀도보다 높은 값만 별로 그림
                stars *= step(0.95, rand(stars_uv.xy)); // 반짝이는 효과를 위한 추가 필터
                
                // --- 성운 생성 ---
                float2 nebula_uv = dir.xy * _NebulaScale;
                // 시간에 따라 성운이 천천히 움직이도록 _Time 사용
                nebula_uv.x += _Time.y * 0.01 * _NebulaSpeed;
                float nebula_noise = fbm(nebula_uv);
                
                // 두 색상을 노이즈 값에 따라 혼합
                fixed4 nebula_color = lerp(_NebulaColor1, _NebulaColor2, nebula_noise);
                nebula_color *= _NebulaDensity; // 성운의 전체 농도 조절

                // --- 최종 색상 조합 ---
                fixed4 final_color = nebula_color + stars * _StarBrightness;
                final_color.rgb *= _SkyTint.rgb; // 전체적인 색감 조절
                
                return final_color;
            }
            ENDCG
        }
    }
}
