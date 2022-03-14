// Upgrade NOTE: replaced '_Object2World' with 'unity_ObjectToWorld'

// Upgrade NOTE: replaced '_Object2World' with 'unity_ObjectToWorld'

// Upgrade NOTE: replaced '_Object2World' with 'unity_ObjectToWorld'

Shader "VolumetricShaders/CloudBall" {
	Properties{
		_Color("color", Color) = (0, 0, 0, 1)
		_Radius("radius", Float) = 4
		_Center("center", Vector) = (0,0,0,0)
		_Center2("Laziness2", Vector) = (0, 0, 0, 0)
		_Center3("Laziness3", Vector) = (0, 0, 0, 0)
		_CloudThickness("Thickness", range(-0.5, 0.5)) = 0.0
		_MaxRenderDistance("Render Distance", range(0, 60000)) = 60000
		_Steps("Steps", range(0, 50)) = 50
		_MapNoise("MapNoise", 3D) = "white"{}
		_MapRand("MapRandom", 2D) = "white"{}
		_lightPosition("Light Position", Vector) = (0, 0, 0, 0)
		_lightColor("Light Color", Color) = (1, 0, 0, 0)
		_AmbientLight("Ambient Light", Vector) = (0.1, 0.1, 0.1, 0.1)
		//_lightPosition("LightPosition", Vector) = (0,0,0,0)
	}
		SubShader{
		Pass{
		Blend SrcAlpha OneMinusSrcAlpha
		ZWrite Off
		//ZTest Always
		CGPROGRAM
#pragma vertex vert
#pragma fragment frag
#include "UnityCG.cginc"
#include "Lighting.cginc"
#define MIN_DISTANCE 0.0001
#define STEP_DISTANCE 0.4
#define MOD2 float2(.16632,.17369)
#define MOD3 float3(.16532,.17369,.15787)
	uniform float _CloudThickness;

	uniform float3 _Center;
	uniform float3 _Center2;
	uniform float3 _Center3;
	
	uniform float _Radius;
	uniform float4 _Color;
	uniform float3 _SunColor = float3(1.0, 1.0, 0.9);
	uniform float3 sunLight = normalize(float3(0.35, 0.14, 0.3));
	uniform float _MaxRenderDistance;
	uniform sampler3D _MapNoise;
	uniform sampler2D _MapRand;
	uniform float4 _MapNoise_TexelSize;
	uniform float4 _MapRand_TexelSize;
	uniform float4 _lightPosition;
	uniform float4 _AmbientLight;
	uniform float4 _lightColor;
	float rand(float3 co)
	{
		return frac(sin(dot(co.xyz, float3(12.9898, 78.233, 45.5432))) * 43758.5453);
	}
	
	float hash(float p)
	{
		float2 p2 = frac(p * MOD2);
		p2 += dot(p2.yx, p2.xy + 19.19);
		return frac(p2.x * p2.y);
	}

	float hash(float3 p)
	{
		p = frac(p * MOD3);
		p += dot(p.xyz, p.yzx + 19.19);
		return frac(p.x * p.y * p.z);
	}
	
	float Sinerp(float start, float end, float value)
	{
		return lerp(start, end, sin(value * 3.14 * 0.5f));
	}

	/*
	float noise(in float2 x)
	{
		float2 p = floor(x);
		float2 f = frac(x);
		f = f*f*(3.0 - 2.0*f);
		float n = p.x + p.y*57.0;
		float res = lerp(lerp(hash(n + 0.0), hash(n + 1.0), f.x),
			lerp(hash(n + 57.0), hash(n + 58.0), f.x), f.y);
		return res;
	}
	float noise(in float3 p)
	{
		float3 i = floor(p);
		float3 f = frac(p);
		f *= f * (3.0 - 2.0*f);

		return lerp(
			lerp(lerp(hash(i + float3(0., 0., 0.)), hash(i + float3(1., 0., 0.)), f.x),
				lerp(hash(i + float3(0., 1., 0.)), hash(i + float3(1., 1., 0.)), f.x),
				f.y),
			lerp(lerp(hash(i + float3(0., 0., 1.)), hash(i + float3(1., 0., 1.)), f.x),
				lerp(hash(i + float3(0., 1., 1.)), hash(i + float3(1., 1., 1.)), f.x),
				f.y),
			f.z);
	}*/

	float noise(in float2 f)
	{
		float2 p = floor(f);
		f = frac(f);
		f = f*f*(3.0 - 2.0*f);
		float res = tex2D(_MapRand, (p + f + .5)).x;
		return res;
	}

	float noise(in float3 x)
	{
		float3 p = floor(x);
		float3 f = frac(x);
		f = f*f*(3.0 - 2.0*f);

		float2 uv = (p.xy + float2(37.0, 17.0)*p.z) + f.xy;
		float2 rg = tex2D(_MapRand, (uv + 0.5) / _MapRand_TexelSize.w).yx;
		return lerp(rg.x, rg.y, f.z);
	}

	float FBM(float3 p)
	{
		return tex3D(_MapNoise, (float3(p.x, p.z, p.y)) - 0.5).r;
		/*
		float3 pt = p;
		p.y = pt.z;
		p.z = pt.y;

		p *= .25;
		float f;

		f = 0.5000 * noise(p); p = p * 3.02; //p.y -= _Time.y*.2;
		f += 0.2500 * noise(p); p = p * 3.03; //p.y += _Time.y*.06;
		f += 0.1250 * noise(p); p = p * 3.01;
		f += 0.0625  * noise(p); p = p * 3.03;
		f += 0.03125  * noise(p); p = p * 3.02;
		f += 0.015625 * noise(p);
		return f; */
	}

	float map(float3 p)
	{

		p *= 0.002;
		float h = FBM(p);
		return h - _CloudThickness - 0.5;

	}

	struct v2f {
		//float4 pos : SV_POSITION;	// Clip space
		float2 uv : TEXCOORD0;
		float3 wPos : TEXCOORD1;	// World position
		float3 cPos : TEXCOORD2; //Camera pos
		float3 cDir : TEXCOORD3;
	};


	v2f vert(float4 vertex : POSITION, // vertex position input
		float2 uv : TEXCOORD0, // texture coordinate input
		out float4 outpos : SV_POSITION // clip space position output
	)
	{
		v2f o;
		//o.pos = mul(UNITY_MATRIX_MVP, v.vertex);
		o.uv = uv;
		o.wPos = mul(unity_ObjectToWorld, vertex).xyz;
		o.cPos = _WorldSpaceCameraPos;
		o.cDir = UNITY_MATRIX_IT_MV[2].xyz;
		outpos = UnityObjectToClipPos(vertex);
		return o;
	}



	float3 normal(float3 p)
	{
		const float eps = 0.01;

		return normalize
		(float3
			(map(p + float3(eps, 0, 0)) - map(p - float3(eps, 0, 0)),
				map(p + float3(0, eps, 0)) - map(p - float3(0, eps, 0)),
				map(p + float3(0, 0, eps)) - map(p - float3(0, 0, eps))
				)
		);
	}

	fixed4 simpleLambert(fixed3 normal) {
		//fixed3 lightDir = _WorldSpaceLightPos0.xyz;	// Light direction
		fixed3 lightDir = float3(0, 1, 0);
		fixed3 lightCol = _LightColor0.rgb;		// Light color

		fixed NdotL = max(dot(normal, lightDir), 0);
		fixed4 c;
		c.rgb = _Color * lightCol * NdotL;
		c.a = 1;
		return c;
	}

	fixed4 renderSurface(float3 pos, float3 wPos, float density, float shadow)
	{
		float3 n = normal(pos);

		/*
		float fLTThickness = density / 10;
		// world space fragment position

		float3 lightDir = normalize(_lightPosition.xyz - wPos);
		//float3 lightDir  = normalize(_lightNormal - wPos);
		float3 vEye = normalize(_WorldSpaceCameraPos - wPos);

		half3 vLTLight = lightDir + n * fLTDistortion;
		half fLTDot = pow(saturate(dot(vEye, -vLTLight)), iLTPower) * fLTScale;
		half3 fLT = fLightAttentuation * (fLTDot + fLTAmbient.rgb) * fLTThickness;*/
		//
		//float4 o = float4(fLT.x, fLT.y, fLT.z, 1);
		//float4 o = simpleLambert(n);

		//Test density lighting
		//float4 o = float4(_LightColor0.x, _LightColor0.y, _LightColor0.z, 1) / shadow;
		float4 o = 1 / shadow;
		o.r = density;
		return o;
	}

	float hVal(float3 p) {
		//+ 0.5
		float h =  (map(((p+ float3(0, -_Time.y * 10, 0)) / 2.5)) * 17);
		h += 0.5;
		//float h = map(p);
		h += min(lerp(-1, 1, distance(float3(p.x, p.y, p.z), _Center) - _Radius /* (((_SinTime.y + 1) / 2.) + 0.5)*/) / (_Radius),
			min(lerp(-1, 1, distance(float3(p.x, p.y, p.z), _Center2) - _Radius /* (((_SinTime.y + 1) / 2.) + 0.5)*/) / (_Radius),
			lerp(-1, 1, distance(float3(p.x, p.y, p.z), _Center3) - _Radius /* (((_SinTime.y + 1) / 2.) + 0.5)*/) / (_Radius)));
		return h;
	}

	uniform float minVal;
	uniform float maxVal;
	uniform float _Steps;
	static const int Steps = 100;

	fixed4 raymarch(float3 position, float3 direction)
	{
		minVal = 2100.0;
		maxVal = 3100.0;
		
		float sunAmount = max(dot(direction, sunLight), 0.0);
		//Density pass
		

		//Start pos
		float beg = ((minVal - position.y) / direction.y);
		float end = ((maxVal - position.y) / direction.y);

		//float3 p = float3(position.x + direction.x * beg, 0.0, position.z + direction.z * beg);
		float3 p = position;
		float3 additional = float3(direction.x, direction.y, direction.z) * STEP_DISTANCE * 5;
		//float3 additional = direction * ((end - beg) / 45.0);
		float difference = maxVal - minVal;
		float density = .0;
		float3 shadow;
		float3 shadowSum = float3(.0, .0, .0);
		shadow.x = 0;
		shadow.y = 0;
		bool begun = false;
		//Individual cloud def
		p += float3(0, 0, _Time.y / 100);
		for (int i = 0; i < 100; i++)
		{
			
			//if (shadowSum.y >= 1.0)
			//	break;
			//Stops calculations after shadow y goes over 1
			int shadowy = 1.0 - max(sign(shadowSum.y - 1), 0.0);
			float h = hVal(p) * shadowy;
			//Cloud density
			shadow.y = max(-h, 0.0) * shadowy;
			//Light bleedthrough
			float3 lightDir = _lightPosition - p;
			float3 p2 = p;
			//Lighting
			shadow.x = saturate(0.5 - max(-h, 0.0) * 10) * shadowy;
			shadow.z = saturate(1 - distance(p, _lightPosition) / 50) * shadowy;
			//ambient light
			//shadow.z = (1 - max(sign(shadow.x - _AmbientLight.w), 0.0)) * shadowy;
			//for (int u = 0; u < 4; u++) {
			//	p2 += lightDir * STEP_DISTANCE * 4;
			//	float h2 = hVal(p2) * shadowy;
			//	shadow.x += saturate(0.5 - max(-h2, 0.0) * 10) / 100;	
			//}
			//Beyeauttiful
			//
			shadowSum += (shadow * (1.0 - shadowSum.y)) * shadowy;
			p += additional ;
		}

		shadowSum.y = clamp(shadowSum.y, 0, 1);
		shadowSum.xz /= 50.0;
		//shadowSum.x = max(shadowSum.x, _AmbientLight.w);
		shadowSum = min(shadowSum, 1.0);
		shadowSum = clamp(shadowSum, 0, 1);
		//float3 clouds = lerp(pow(shadowSum.x, 0.4), _LightColor, (1.0 - shadowSum.y) * 0.4);
		float3 clouds = lerp(pow(shadowSum.x, 1) * 1, 1, (1.0 - shadowSum.y) * 0.4);
		clouds += lerp(shadowSum.z * _lightColor, 1, (1.0 - shadowSum.y));
		//clouds += (1 - max(sign(shadow.x - _AmbientLight.w), 0.0)) * _AmbientLight.xyz;
		//clouds += min((1.0 - sqrt(shadowSum.y)) * pow(sunAmount, 4.0), 1.0) * 2.0;
		clouds += min((1.0 - sqrt(shadowSum.y)) * 0.01, 1.0) * 2.0;
		//return float4(clouds.x, clouds.y, clouds.z, 1.0) / 10;
		//sky = lerp(sky, min(clouds, 1.0), shadowSum.y);
		///sky = lerp(float4(0, 0, 0, 0), min(clouds, 1.0), shadowSum.y);
		float3 cMin = min(clouds, 1.0);
		float4 sky2 = lerp(float4(0, 0, 0, 0), float4(cMin.x, cMin.y, cMin.z, 1), shadowSum.y);;
		return clamp(float4(sky2.x, sky2.y, sky2.z, sky2.a), 0.0, 1.0);
		//return float4(sky.x, sky.y, sky.z, 1.0);
	}

	uniform sampler2D _CameraDepthTexture;

	sampler2D _CurrentDepth;

	struct fragOut {
		half4 color : COLOR;
		float depth : DEPTH;
	};

	//fragOut frag(v2f i, UNITY_VPOS_TYPE screenPos : VPOS) : SV_Target{
	fragOut frag( v2f i){
		fragOut o;
	//float2 xy = screenPos.xy / _ScreenParams.xy;
	//float2 uv = (-1.0 + 2.0 * xy) * float2(_ScreenParams.x / _ScreenParams.y, 1.0);
	float3 viewDirection = normalize((i.wPos) - i.cPos);
	//float depth = LinearEyeDepth(tex2D(_CurrentDepth, i.uv).r);
	//o.depth = -5;
	
	//float depthTest = LinearEyeDepth(tex2D(_CameraDepthTexture, i.uv).b);
	//o.depth = -tex2D(_CurrentDepth, i.uv).r;
	//o.color = float4(depthTest, depthTest, depthTest, 1);
	//return o;
	//Current depth of the render target

	//o.color = raymarch(i.wPos, float3(viewDirection.x, viewDirection.y, viewDirection.z));
	o.color = raymarch(i.wPos, viewDirection);
	return o;
	}
		ENDCG
	}
	}
}
