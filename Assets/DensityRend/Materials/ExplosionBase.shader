// Upgrade NOTE: replaced '_Object2World' with 'unity_ObjectToWorld'

// Upgrade NOTE: replaced '_Object2World' with 'unity_ObjectToWorld'

// Upgrade NOTE: replaced '_Object2World' with 'unity_ObjectToWorld'

Shader "Custom/Explosion" {
	Properties{
		_Color("color", Color) = (0, 0, 0, 1)
		_Radius("radius", Float) = 4
		_Center("center", Vector) = (0,0,0,0)
		_LightNormal("Light Normal", Vector) = (0,0,0,0)
		_LightColor("light color", Color) = (1, 1, 1, 1)
		_ThicknessTex("Thickness Precalc", 2D) = "black" {}
	_OcclusionTex("Occlusion Map", 2D) = "white" {}
	_Glossiness("Smoothness", Range(0,1)) = 0.5
		_Metallic("Metallic", Range(0,1)) = 0.0
		_CloudThickness("Thickness", range(-0.5, 0.5)) = 0.0
		fLTDistortion("Distortion", Range(0,2)) = 0.0
		iLTPower("Power", Range(0,50)) = 1.0
		fLTScale("Scale", Range(0,10)) = 1.0
		fLightAttentuation("Attentuation", Range(0,10)) = 1.0
		fLTAmbient("Ambient", Color) = (0,0,0,1)
		//_lightPosition("LightPosition", Vector) = (0,0,0,0)
	}
		SubShader{
		Pass{
		Blend SrcAlpha OneMinusSrcAlpha

		CGPROGRAM
#pragma vertex vert
#pragma fragment frag
#include "UnityCG.cginc"
#include "Lighting.cginc"
#define STEPS 50
#define MIN_DISTANCE 0.0001
#define STEP_DISTANCE 0.4
#define MOD2 float2(.16632,.17369)
#define MOD3 float3(.16532,.17369,.15787)
		float _CloudThickness;
	float3 _Center;
	float _Radius;
	float4 _Color;
	//SSS
	float fLTDistortion;
	float fLTScale;
	float iLTPower;
	fixed4 fLTAmbient;
	float fLightAttentuation;
	float4 _lightPosition;
	float3 _lightNormal;
	vector _Positions[6];
	float3 _SunColor = float3(1.0, 1.0, 0.9);
	float3 sunLight = normalize(float3(0.35, 0.14, 0.3));

	float rand(float3 co)
	{
		return frac(sin(dot(co.xyz, float3(12.9898, 78.233, 45.5432))) * 43758.5453);
	}
	/*
	float hash(float p)
	{
	float3 p2 = frac(p * MOD3);
	p2 += dot(p2.yx, p2.xy + 19.19);
	return frac(p2.x * p2.y);
	}
	float hash(float3 p)
	{
	p = frac(p * MOD3);
	p += dot(p.xyz, p.yzx + 19.19);
	return frac(p.x * p.y * p.z);
	}
	*/
	/*
	float hash(float n)
	{
	return frac(sin(n)*43758.5453);
	}*/
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
	/*
	float noise(float x)
	{
	// The noise function returns a value in the range -1.0f -> 1.0f

	float3 p = floor(x);
	float3 f = frac(x);

	f = f*f*(3.0 - 2.0*f);
	float n = p.x + p.y*57.0 + 113.0*p.z;

	return lerp(lerp(lerp(hash(n + 0.0), hash(n + 1.0), f.x),
	lerp(hash(n + 57.0), hash(n + 58.0), f.x), f.y),
	lerp(lerp(hash(n + 113.0), hash(n + 114.0), f.x),
	lerp(hash(n + 170.0), hash(n + 171.0), f.x), f.y), f.z);
	}*/
	/*
	float noise(float3 x)
	{
	// The noise function returns a value in the range -1.0f -> 1.0f

	float3 p = floor(x);
	float3 f = frac(x);

	f = f*f*(3.0 - 2.0*f);
	float n = p.x + p.y*57.0 + 113.0*p.z;

	return lerp(lerp(lerp(hash(n + 0.0), hash(n + 1.0), f.x),
	lerp(hash(n + 57.0), hash(n + 58.0), f.x), f.y),
	lerp(lerp(hash(n + 113.0), hash(n + 114.0), f.x),
	lerp(hash(n + 170.0), hash(n + 171.0), f.x), f.y), f.z);
	}*/

	float Sinerp(float start, float end, float value)
	{
		return lerp(start, end, sin(value * 3.14 * 0.5f));
	}


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
	}

	bool bdf_sphere(float p, float c, float r) {
		return distance(p, c) < r;
	}

	float sdf_blend(float d1, float d2, float a)
	{
		return a * d1 + (1 - a) * d2;
	}

	float sdf_smin(float a, float b, float k = 32)
	{
		float res = exp(-k*a) + exp(-k*b);
		return -log(max(0.0001, res)) / k;
	}

	float sdf_sphere(float3 p, float3 c, float r)
	{
		return distance(p, c) - r;
	}

	float sdf_box(float3 p, float3 c, float3 s)
	{
		float x = max
		(p.x - _Center.x - float3(s.x / 2, 0, 0),
			_Center.x - p.x - float3(s.x / 2., 0, 0)
		);

		float y = max
		(p.y - _Center.y - float3(s.y / 2., 0, 0),
			_Center.y - p.y - float3(s.y / 2., 0, 0)
		);

		float z = max
		(p.z - _Center.z - float3(s.z / 2., 0, 0),
			_Center.z - p.z - float3(s.z / 2., 0, 0)
		);

		float d = x;
		d = max(d, y);
		d = max(d, z);
		return d;
	}

	float FBM(float3 p)
	{
		p *= .25;
		float f;

		f = 0.5000 * noise(p); p = p * 3.02; //p.y -= _Time.y*.2;
		f += 0.2500 * noise(p); p = p * 3.03; //p.y += _Time.y*.06;
		f += 0.1250 * noise(p); p = p * 3.01;
		f += 0.0625  * noise(p); p = p * 3.03;
		f += 0.03125  * noise(p); p = p * 3.02;
		f += 0.015625 * noise(p);
		return f;
	}

	float map(float3 p)
	{

		p *= 0.002;
		float h = FBM(p);
		return h - _CloudThickness - 0.5;

	}

	struct v2f {
		//float4 pos : SV_POSITION;	// Clip space
		float3 wPos : TEXCOORD0;	// World position
		float3 cPos : TEXCOORD1; //Camera pos
	};


	v2f vert(float4 vertex : POSITION, // vertex position input
		float2 uv : TEXCOORD0, // texture coordinate input
		out float4 outpos : SV_POSITION // clip space position output
	)
	{
		v2f o;
		//o.pos = mul(UNITY_MATRIX_MVP, v.vertex);
		o.wPos = mul(unity_ObjectToWorld, vertex).xyz;
		o.cPos = _WorldSpaceCameraPos;
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

	float4 gradient3(float4 color1, float4 color2, float4 color3, float middle, float val) {
		float4 c = lerp(color1, color2, val / middle) * step(val, middle);
		c += lerp(color2, color3, (val - middle) / (1 - middle)) * step(middle, val);
		return c;
	}

	fixed4 raymarch(float3 position, float3 direction, out float2 outPos)
	{
		/*
		float sunAmount = max(dot(direction, sunLight), 0.0);
		//Density pass
		float3 minVal = 2000.0;
		float3 maxVal = 3800.0;

		//Start pos
		float beg = ((minVal - position.y) / direction.y);
		float end = ((maxVal - position.y) / direction.y);

		//float3 p = float3(position.x + direction.x * beg, 0.0, position.z + direction.z * beg);*/
		float3 p = float3(position.x, position.y, position.z);
		
		//beg += hash(p) * 150.;
		//p += hash(p) * 150.;
		outPos = p.xz;
		
		//float d = 0.0;
		float3 additional = float3(direction.x, direction.y, direction.z);
		/*
		float difference = maxVal - minVal;
		float density = .0;*/
		float2 shadow;
		float2 shadowSum = float2(0.0, .0);
		float4 testColor = 0;
		shadow.x = 0.01;
		p = position;
		p += additional;
		_Radius = Sinerp(0, _Radius, (cos(_Time.y * 5) + 1) / 2);
		//Individual cloud def
		for (int i = 0; i < STEPS; i++)
		{
			float dfs = sdf_sphere(p, _Center, _Radius * 5);
			
			if (dfs < MIN_DISTANCE) {
				for (int u = 0; u < STEPS; u++)
				{
					//if (distance(p, _Center) > _Radius && dot(normalize(p - _Center), _Center - direction ) < 0)
					//	return 1;
					if (shadowSum.y >= 1.0)
						break;
					//if (distance(p, _Center) < _Radius * 5)
					//	return 1;
					float d = distance(p, _Center) - _Radius;
					float h = map((p + float3(sin(_Time.y), 0, 0)) * 100.0);

					//return h;
					h *= 4;
					h += lerp(-1, 1, d) / (_Radius);
					//return float4(-h, -h, -h, 1) + 0.5;
					//if((-h + 0.5) <= 0)
					//	continue;

					if (h >= 4) {
						p += additional;
						continue;
					}
					else {
						
						//testColor = (gradient3(float4(1, 0.5, 0.1, 1), float4(0.9, 0.7, 0.7, 1), float4(1, 1, 1, 1), 0., distance(p, _Center))) / 10;
						float distFuck = distance(p, _Center) / 50;
						//testColor = float4(distFuck, distFuck, distFuck, 1);
						return testColor = (gradient3(float4(1, 1, 1, 1), float4(1, 0.5, 0.1, 1), float4(0.4, 0, 0, 1), 0.9, distFuck));
						//break;
					}
				}

				p += dfs * direction;
			}
			
			//return h;
			//clip(-1 * h);
			//shadow.y = max(-h, 0.0);
			//shadow.x = lerp(-1, 1, distance(p, _Center) - _Radius) / (_Radius / 1.) / 20.;
			//shadowSum += shadow * (1.0 - shadowSum.y);
			//testColor += (gradient3(float4(1, 0.5, 0.1, 1), float4(0.9, 0.7, 0.7, 1), float4(1, 1, 1, 1), 0.5, saturate((1 - h) * d))) / 25 ;
			
			//if (h < 0.01) {
			//p += additional * (1.0 / h);
			//}
			//else {
			p += additional;
			//}


		}
		return float4(testColor.x, testColor.y, testColor.z, testColor.w);
		shadowSum.x /= 10.0;
		shadowSum = min(testColor, 1.0);
		float3 clouds = lerp(pow(testColor.x, .4), _SunColor, (1.0 - testColor.y) * 0.4);
		//clouds += max((1.0 - sqrt(shadowSum.y)) * pow(sunAmount, 4.0), 1.0) * 2.0;
		//clouds += min((1.0 - sqrt(shadowSum.y)) * pow(sunAmount, 4.0), 1.0) * 2.0;
		//return float4(clouds.x, clouds.y, clouds.z, 1.0) / 10;
		//sky = lerp(sky, min(clouds, 1.0), shadowSum.y);
		///sky = lerp(float4(0, 0, 0, 0), min(clouds, 1.0), shadowSum.y);
		float3 cMin = min(clouds, 1.0);
		float4 sky2 = lerp(float4(0, 0, 0, 0), float4(cMin.x, cMin.y, cMin.z, 1), testColor.y);;
		return clamp(float4(sky2.x, 0, 0, sky2.a), 0.0, 1.0);
		return clamp(float4(sky2.x, sky2.y, sky2.z, sky2.a), 0.0, 1.0);

		//return float4(sky.x, sky.y, sky.z, 1.0);
	}


	float3 CameraPath(float t)
	{
		return float3(4000.0 * sin(.16*t) + 12290.0, 0.0, 8800.0 * cos(.145*t + .3));
	}

	struct fragOut {
		half4 color : COLOR;
		float depth : DEPTH;
	};

	fragOut frag(v2f i, UNITY_VPOS_TYPE screenPos : VPOS) : SV_Target{
		//return 0;
		fragOut o;
	float3 worldPosition = i.wPos;
	float2 xy = screenPos.xy / _ScreenParams.xy;
	float2 uv = (-1.0 + 2.0 * xy) * float2(_ScreenParams.x / _ScreenParams.y, 1.0);

	float3 viewDirection = normalize(i.wPos - _WorldSpaceCameraPos);
	//float3 viewDirection = normalize(uv.x*cu + uv.y*cv + 1.3*cw);
	float2 outPos = 0.;
	//return float4(0, 0, 0, 0);
	o.color = raymarch(i.wPos, float3(viewDirection.x, viewDirection.y, viewDirection.z), outPos);
	o.depth = 1;
	return o;
	}


		ENDCG
	}
	}
}
