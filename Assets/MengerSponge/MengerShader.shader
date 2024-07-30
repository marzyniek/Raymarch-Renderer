Shader "Martin/MengerShader"
{
    Properties
    {
        _MainTex ("Texture", 2D) = "white" {}
    }
    SubShader
    {
        // No culling or depth
        Cull Off ZWrite Off ZTest Always

        Pass
        {
            CGPROGRAM
            #pragma vertex vert
            #pragma fragment frag
            #pragma target 5.0
            

            #include "UnityCG.cginc"
            #include "../Shared/DistanceFunctions.cginc"
           
            sampler2D _MainTex;
            //Uniforms
            uniform float4x4 _CamFrustum, _CamToWorld;
            uniform float _maxDistance;
            uniform float _maxSteps;
            uniform float _surfDist;

            uniform float3 _lightPos;

            uniform float _colorIntensity;
            uniform float3 _glowColor;
            uniform float _glowIntensity;

            uniform float3 _replicate;
            uniform float _offset;

            uniform float3 _mengerPos;
            uniform int _mengerIteratios;
            uniform float _mengerWidth;
            uniform float3 _mengerColor;
            uniform float3 _difColor;

            uniform int _showPlane;
            uniform float3 _planeColor;

            uniform float3 _rotation;

            struct appdata
            {
                float4 vertex : POSITION;
                float2 uv : TEXCOORD0;
            };
            
            struct v2f
            {
                float2 uv : TEXCOORD0; 
                float4 vertex : SV_POSITION;
                float3 ray : TEXCOORD1;
            };
            
            float4 _MainTex_ST;

            v2f vert (appdata v)
            {
                v2f o;
                half index = v.vertex.z;
                v.vertex.z = 0;
                o.vertex = UnityObjectToClipPos(v.vertex);
                o.uv = v.uv;
                o.ray = _CamFrustum[(int)index].xyz;

                o.ray = normalize(o.ray);

                o.ray = mul(_CamToWorld, o.ray);
                return o;
            }
            
            float4 getDist(float3 p){
                float4 Scene;

                float3 mengerP = p - _mengerPos;
                
                mengerP.yz = mul(Rotate(_rotation.x), mengerP.yz);
                mengerP.xz = mul(Rotate(_rotation.y), mengerP.xz);
                mengerP.xy = mul(Rotate(_rotation.z), mengerP.xy);

                if (_replicate.x) {
                    mengerP.x = repCoord(mengerP.x, _offset);
                }
                if (_replicate.y) {
                    mengerP.y = repCoord(mengerP.y, _offset);
                }
                if (_replicate.z) {
                    mengerP.z = repCoord(mengerP.z, _offset);
                }
                
                float4 Menger = float4(_mengerColor, sdMenger2(mengerP, _mengerIteratios, _mengerWidth)); 
                Scene = Menger;
                
                if (_showPlane) {
                    float4 Plane = float4(_planeColor, sdPlane(p, float3(0.0, 1.0, 0.0), 0.0));
                    Scene = opColU(Scene, Plane);
                }
                
                return Scene;
            }



            float2 RayMarch(float3 ro, float3 rd){
                float dO = 0.;
                int steps;
                for (steps = 0; steps <_maxSteps; steps++){ 
                    if (dO>_maxDistance){
                        break;
                        _difColor = float3(1.,1.,1.);
                    } 
                    float3 p = ro + rd * dO;
                    float4 dS = getDist(p);
                    if (dS.w < _surfDist){
                        _difColor = dS.rgb; // +float3(sin(2.*length(p)), cos(30.*length(p)) , sin(5.*length(p)))/2. ; //+ float3(i/_maxSteps, i/_maxSteps, i/_maxSteps);
                        break;
                    }
    
                    dO += dS.w;
                } 
               return float2 (dO, steps);
            }
            float3 getNormal(float3 p){
                float d = getDist(p).w;
                float2 e = float2(0.00005, 0);
                float3 n = d - float3(
                    getDist(p-e.xyy).w, 
                    getDist(p-e.yxy).w, 
                    getDist(p-e.yyx).w);
                return normalize(n);
            }
            
            uniform float _AOStepsize, _AOIntensity;
            uniform int _AOIterations;
            
            float ambientOcclusion (float3 p, float3 n)
            {
                float step = _AOStepsize;
                float ao = 0.0;
                float dist;

                for (int i = 1; i <= _AOIterations; i++)
                {
                    dist = step * i;
                    ao += max(0.0, (dist - getDist(p + n * dist).w)/dist);
                } 
                return (1.0 - (ao * _AOIntensity));

            }
            
            float getShadow(float3 p, float d)
            {
                float result = 1.0;
                if(d < length(_lightPos - p)) {
                    return 0.2;
                }
                return result;
            }   
            
            float3 getLight(float3 p, float3 c, float steps){
                float3 color = _difColor * _colorIntensity;
                
                float3 lightPos =  _lightPos; 
                
                float3 l = normalize(lightPos - p);
                
                float3 n = getNormal(p);

                float ao = ambientOcclusion(p, n);
                
                float dif = clamp(dot(n, l), 0.,1.);
                float d = RayMarch(p + n*_surfDist*2., l).x;
                float shadow = getShadow(p, d);
                float3 glow = _glowColor * pow(steps/70., 2) * _glowIntensity;
                return dif*shadow * color * ao + glow ;
            }
            
            fixed4 frag(v2f i) : SV_Target
            {
                fixed3 col = tex2D(_MainTex, i.uv);
               // float3 col = 0;
                float3 rd = i.ray.xyz;
                float3 ro = _WorldSpaceCameraPos;

                float2 d = RayMarch(ro, rd);
    
                float3 p = ro + rd * d.x; 
                float3 dif = getLight(p, _difColor, d.y);
                col = dif + float3(0.1,0.1,0.1);
                float4 fragColor = float4(col.rgb,1.0);
                fragColor = float4(dif, 1);
                return fragColor;
            }
            ENDCG
        }
    }
}
