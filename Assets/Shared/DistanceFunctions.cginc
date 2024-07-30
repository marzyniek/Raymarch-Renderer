#include "Utils.cginc"

#ifndef DISTANCE_FUNCTIONS_CGINC
#define DISTANCE_FUNCTIONS_CGINC


//--------------------------------------OBJECTS-------------------------------------------
// Sphere
// s: radius
float sdSphere(float3 p, float s)
{
	return length(p) - s;
}

//Plane
float sdPlane( float3 p, float3 n, float h )
{
    n = normalize(n);
    return dot(p,n) + h;
}
// Torus
// t: x and y radius
float sdTorus( float3 p, float2 t )
{
  float2 q = float2(length(p.xy)- t.x,p.z);
  return length(q)-t.y;
 }

// Box
// b: size of box in x/y/z
float sdBox(float3 p, float3 b)
{
	float3 d = abs(p) - b;
	return min(max(d.x, max(d.y, d.z)), 0.0) +
		length(max(d, 0.0));
}
// Pyramid
//
float sdTetrahedron( float3 p, float a)
{
  return(max( abs(p.x+p.y)-p.z, abs(p.x-p.y)+p.z )-a)/sqrt(3.);
}

//Infinite Cylinder
float sdCylinder( float3 p, float3 c )
{
  return length(p.xz-c.xy)-c.z;
}
//Cone
float sdCone( in float3 p, in float2 c, float h )
{
  // c is the sin/cos of the angle, h is height

  float2 q = h*float2(c.x/c.y,-1.0);
    
  float2 w = float2( length(p.xz), p.y );
  float2 a = w - q*clamp( dot(w,q)/dot(q,q), 0.0, 1.0 );
  float2 b = w - q*float2( clamp( w.x/q.x, 0.0, 1.0 ), 1.0 );
  float k = sign( q.y );
  float d = min(dot( a, a ),dot(b, b));
  float s = max( k*(w.x*q.y-w.y*q.x),k*(w.y-q.y)  );
  return sqrt(d)*sign(s);
}

//Infinite cone
float sdCone( float3 p, float2 c )
{
    // c is the sin/cos of the angle
    float2 q = float2( length(p.xz), -p.y );
    float d = length(q-c*max(dot(q,c), 0.0));
    return d * ((q.x*c.y-q.y*c.x<0.0)?-1.0:1.0);
}
//Cross
float sdCross(float3 p, float l,  float w)
{
  float a = sdBox(p, float3(l, w, w));
  float b = sdBox(p, float3(w, l, w));
  float c = sdBox(p, float3(w, w, l));
  return opU(a, opU(b, c));
}
//Infinite Cross
float sdInfCross(float3 p){ 
  float da = max(abs(p.x), abs(p.y));
  float db = max(abs(p.y), abs(p.z));
  float dc = max(abs(p.z), abs(p.x));
  return min(da,min(db,dc))-1.0;
}
//BoxFrame
float sdBoxFrame(float3 p, float w) 
{
  return opS(sdCross(p, w*1.02, w*0.98), sdBox(p, w));
}

//Sierpinsky trinagle
float sdFraktal(float3 p, float scale, float it){
  float3 a1 = float3(1,1,1);
  float3 a2 = float3(-1,-1,1);
	float3 a3 = float3(1,-1,-1);
	float3 a4 = float3(-1,1,-1);
	float3 c;
	int n = 0;
	float dist, d;
	while (n < it) {
	  c = a1; dist = length(p-a1);
	  d = length(p-a2); if (d < dist) { c = a2; dist=d; }
		d = length(p-a3); if (d < dist) { c = a3; dist=d; }
		d = length(p-a4); if (d < dist) { c = a4; dist=d; }
		p = scale*p-c*(scale-1.0);
		n++;
	}

	return  length(p) * pow(scale, float(-n));

}
float sdMyFraktal(float3 p, float it, float w){
  float tetra = sdTetrahedron(p, w);
  return tetra;
}

//Menger Sponge
float sdMengerSponge(float3 p, int it, float w){
  float Box = sdBox(p, w);
  float s = 1.;
  for(int i = 0; i < it; i++)
  {
      float3 a = fmod((p+2)*s, 2.0 )-1.0;
      s *= 3.0;
      float3 r = abs(1 - 3.0*abs(a));
      float c = sdCross(r, 100, 1)/s;
      Box = c;//max(Box,c);
  }
  return Box;
}
float sdMenger2(float3 p, int it, float w)
{
  float Box = sdBox(p, w);
  float s = 1.;
  for (int i = 0; i<it; i++){
    float3 crossP = repCoords(p + w, 2*w/s);//, repCoord(p.y + w, 2*w/s), repCoord(p.z + w, 2*w/s));
    float Cross = sdCross(crossP, 100., (w/3.)/s);
    Box = opS(Cross, Box);
    s*=3;
  }
  return Box;
}

#endif
 