Shader "Martin/UtilShader"
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
            uniform float3 _difColor;
            uniform float3 _lightPos;
            
            uniform int _smooth;
            uniform float _smoothness;

            uniform float3 _planeColor;

            uniform float4 _box1;
            uniform float3 _box1Color;
            
            uniform float4 _box2;
            uniform float3 _box2Color;
            
            uniform float4 _box3;
            uniform float3 _box3Color;
            
            uniform float4 _box4;
            uniform float3 _box4Color;

            uniform float4 _sphere;
            uniform float3 _sphere1Color;
            uniform float3 _sphere2Color;
            
            uniform float4 _torus;
            uniform float3 _torusColor;

            uniform int _rotate;
            uniform float3 _rotation;
            
            uniform float3 _glowColor;
            uniform float _glowIntensity;
            uniform int _mirror;
            
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

                _sphere.y = sin(_Time.y)*2.;
                float3 boxP1 = p - _box1.xyz;
                float3 boxP2 = p - _box2.xyz;
                float3 boxP3 = p - _box3.xyz;
                float3 boxP4 = p - _box4.xyz;

                float4 Plane = float4(1.0, 1.0, 1.0, p.y);
                float4 Sphere1 = float4(_sphere1Color, sdSphere(float3(boxP1.x, boxP1.y, boxP1.z + sin(_Time.y)*_box1.w*2), _box1.w));
                float4 Sphere2 = float4(_sphere2Color, sdSphere(float3(boxP3.x, boxP3.y, boxP3.z + sin(_Time.y)*_box3.w*2), _box3.w*1.5));
                float4 Torus = float4(float3(_torusColor), sdTorus(float3(boxP2.x, boxP2.y,  sin(_Time.y)*_box3.w*1.5 + boxP2.z) , float2(_box1.w/1.75, _box1.w/3.5)));


                if(_rotate == 1){ 
                    boxP1.xz = mul(Rotate(_Time.x*6. % 6.28), boxP1.xz);
                    boxP2.xz = mul(Rotate(_Time.x*6. % 6.28), boxP2.xz);
                    boxP3.xz = mul(Rotate(_Time.x*6. % 6.28), boxP3.xz);
                }
               
                float4 Box1 = float4(_box1Color.rgb, sdBox(boxP1, _box1.w));
                float4 Box2 = float4(_box3Color.rgb, sdBox(boxP2, _box2.w));
                float4 Box3 = float4(_box2Color.rgb, sdBox(boxP3, _box3.w));
               
                float4 BoxFrame1 = float4(float3(1., 0., 0.), sdBoxFrame(boxP1, _box1.w));
                float4 BoxFrame2 = float4(float3(1., 0., 0.), sdBoxFrame(boxP2, _box2.w));
                float4 BoxFrame3 = float4(float3(1., 0., 0.), sdBoxFrame(boxP3, _box3.w));


                Scene = opColU(Plane, Plane);
                Scene = opColU(Scene, BoxFrame1);
                Scene = opColU(Scene, BoxFrame2);
                Scene = opColU(Scene, BoxFrame3);
                if(_smooth){
                    Scene = opColU(Scene, opSmoothColU(Sphere1, Box1, _smoothness));
                    Scene = opColU(Scene, opSmoothColS(Box3, Sphere2, _smoothness));
                    Scene = opColU(Scene, opSmoothColI(Torus, Box2, _smoothness));
                }
                else{
                    Scene = opColU(Scene, opColU(Sphere1, Box1));
                    Scene = opColU(Scene, opColS(Box3, Sphere2));
                    Scene = opColU(Scene, opColI(Torus, Box2));
                   
                }

                return Scene;
                
            }



            float2 RayMarch(float3 ro, float3 rd){
                float dO = 0.;
                int steps;
                for (steps = 0; steps <_maxSteps; steps++){ 
                    if (dO  >_maxDistance){
                        break;
                        _difColor = float3(1.,1.,1.);
                    } 
                    float3 p = ro + rd * dO;
                    float4 dS = getDist(p);
                    if (dS.w < _surfDist){
                        _difColor = dS.rgb;
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
                float3 color = _difColor;
                
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
