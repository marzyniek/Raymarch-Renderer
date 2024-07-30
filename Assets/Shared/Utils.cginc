#ifndef UTILS_CGINC
#define UTILS_CGINC

// BOOLEAN OPERATORS //
float2x2 Rotate (float angle) {
  float s = sin(angle);
  float c = cos(angle);
  return float2x2(c, -s, s, c);
}
// Union
float opU(float d1, float d2)
{
	return min(d1, d2);
}
//color Union
float4 opColU(float4 d1, float4 d2)
{
	float d = min(d1.w, d2.w);
  return d == d1.w? d1 : d2;
}

// Subtraction
float opS(float d1, float d2)
{
	return max(-d1, d2);
}

float4 opColS(float4 d1, float4 d2)
{
	float d = max(-d1.w, d2.w);
  return d == -d1.w? float4(d1.r, d1.g, d1.b, -d1.w) : d2;
}
// Intersection
float opI(float d1, float d2)
{
	return max(d1, d2);
}
float4 opColI(float4 d1, float4 d2)
{
	float d = max(d1.w, d2.w);
  return d == d1.w? d1 : d2;
}


// Smooth union
float opSmoothUnion( float d1, float d2, float k ) {
    float h = clamp( 0.5 + 0.5*(d2-d1)/k, 0.0, 1.0 );
    return lerp( d2, d1, h ) - k*h*(1.0-h);
    }
// Smooth color union

float4 opSmoothColU( float4 d1, float4 d2, float k ) {
    float h = clamp( 0.5 + 0.5*(d2.w-d1.w)/k, 0.0, 1.0 );
    float d = lerp( d2.w, d1.w, h ) - k*h*(1.0-h);
    float3 c = lerp(d2.rgb, d1.rgb, h);
    return float4(c, d );
    }

// Smooth subtraction
float opSmoothSubtraction( float d1, float d2, float k ) {
    float h = clamp( 0.5 - 0.5*(d2+d1)/k, 0.0, 1.0 );
    return lerp( d2, -d1, h ) + k*h*(1.0-h); 
}

// Smooth Color subtraction
float4 opSmoothColS( float4 d1, float4 d2, float k ) {
    k = -k;
    float h = clamp( 0.5 + 0.5*(d2.w+d1.w)/k, 0.0, 1.0 );
    float d = lerp( d2.w, -d1.w, h ) - k*h*(1.0-h);
    float3 c = lerp(d2.rgb, d1.rgb, h);
    return float4(c, d );
}

// Smooth intersection
float opSmoothIntersection( float d1, float d2, float k ) {
    float h = clamp( 0.5 - 0.5*(d2-d1)/k, 0.0, 1.0 );
    return lerp( d2, d1, h ) + k*h*(1.0-h); 
}

float4 opSmoothColI( float4 d1, float4 d2, float k ) {
    float h = clamp( 0.5 - 0.5*(d2.w - d1.w)/k, 0.0, 1.0 );
    float d = lerp( d2.w, d1.w, h ) + k*h*(1.0-h);
    float3 c = lerp(d2.rgb, d1.rgb, h);
    return float4(c, d );
}

// Mod Position Axis
float repCoord(float coord, float s){
    float3 q = fmod(abs(coord), s) - 0.5*s;
    return q;
}
float3 repCoords(float3 p, float s){
    float3 q = fmod(abs(p), s) - 0.5*s;
    return q;
}

float pMod1 (inout float p, float size)
{
	float halfsize = size * 0.5;
	float c = floor((p+halfsize)/size);
	p = fmod(p+halfsize,size)-halfsize;
	p = fmod(-p+halfsize,size)-halfsize;
	return c;
}

float3 opRepLim( inout float3 p, inout float c, inout float3 l )
{
    float3 q = p-c*clamp(round(p/c),-l,l);
    return q;
}

float3 fold(float3 p, float3 n)
{
  float t = dot(p ,n); 
  if (t<0.0) {
     p -= 2.0*t*n; 
  }
  return p;
}

float3 sphereFold(float3 p, inout float dz, float minRadius2, float fixedRadius2) {
	float r = length(p);
  float r2 = dot(p,p);
	if (r<minRadius2) { 
		// linear inner scaling
		float temp = (fixedRadius2/minRadius2);
		p *= temp;
		dz*= temp;
	} else if (r2<fixedRadius2) { 
		// this is the actual sphere inversion
		float temp =(fixedRadius2/r2);
		p *= temp;
		dz*= temp;
	}
  return float3(p);
}

float3 boxFold(float3 p, float foldingLimit) {
	p = clamp(p, -foldingLimit, foldingLimit) * 2.0 - p;
  return p;
}

#endif