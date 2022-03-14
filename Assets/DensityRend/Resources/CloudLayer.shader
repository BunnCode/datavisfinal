// Upgrade NOTE: replaced '_Object2World' with 'unity_ObjectToWorld'

// Upgrade NOTE: replaced '_Object2World' with 'unity_ObjectToWorld'

// Upgrade NOTE: replaced '_Object2World' with 'unity_ObjectToWorld'

Shader "VolumetricShaders/CloudLayer" {
	Properties{
		_Color("color", Color) = (0, 0, 0, 1)
		_Radius("radius", Float) = 4
		_Center("center", Vector) = (0,0,0,0)
		_CloudThickness("Thickness", range(-0.5, 0.5)) = 0.0
		_MaxRenderDistance("Render Distance", range(0, 60000)) = 60000
		_Steps("Steps", range(0, 50)) = 50
		//_MapNoise("MapNoise", 3D) = "white"{}
		_MapRand("MapRandom", 2D) = "white"{}
	    _AmbientLight("Ambient Light", Color) = (0.2, 0, 0, 1)
		_Density("Density", Float) = 4
		//_SunColor("Sun Color", Color) = (1, 1, 1, 1)
		//_lightPosition("LightPosition", Vector) = (0,0,0,0)
	}
		SubShader{
		Pass{
		Blend SrcAlpha OneMinusSrcAlpha
		//Blend SrcAlpha Zero
		ZWrite Off
		ZTest GEqual
		CGPROGRAM
#pragma target 3.0
#pragma vertex vert
#pragma fragment frag

#include "UnityCG.cginc"
#include "Lighting.cginc"
#include "DodgeIf.cginc"

#define MOD2 float2(.16632,.17369)
#define MOD3 float3(.16532,.17369,.15787)
			//Why are clouds stopping at 1k altitude?
#define minHeight 100.0
#define	maxHeight 5600.0
#define MinStepDist 20
		//#define MaxStepDist 100
#define MaxStepDist 500
		//#define _Density 4

		//Camera information

		uniform float3 _CameraPosition;
	//uniform float3 _CameraRight;
	//uniform float4 _CameraUp;
	//uniform float4 _CameraForward;

	//Cloud information
	uniform float _CloudThickness;
	uniform float4 _Color;
	uniform float3 _SunColor = float3(1.0, 1.0, 0.9);
	uniform float4 _AmbientLight;
	uniform float3 _SunPos = float3(0, 0, 0);
	uniform float3 _SunDir = float3(0, 0, 0);
	uniform float _MaxRenderDistance;
	uniform sampler3D _MapNoise;
	uniform sampler2D _MapRand;
	uniform float4 _MapNoise_TexelSize;
	uniform float _AspectRatio;
	uniform float _FieldOfView;
	uniform float _Density;
	uniform float4x4 _LeftEyeVectorMatrix;
	uniform float4x4 _RightEyeVectorMatrix;
	uniform float _EyeOffset;
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
		float res = tex2Dlod(_MapRand, float4(p.x + f.x + .5, p.y + f.y + .5, 0.0, 0.0)).x;
		return res;
	}

	float noise(in float3 x)
	{
		float3 p = floor(x);
		float3 f = frac(x);
		f = f*f*(3.0 - 2.0*f);

		float2 uv = (p.xy + float2(37.0, 17.0)*p.z) + f.xy;
		float4 index = float4(((uv + 0.5) / 64).x, ((uv + 0.5) / 64).y, 0, 0);
		float2 rg = tex2Dlod(_MapRand, index).yx;
		return lerp(rg.x, rg.y, f.z);
		//return 0;
	}

	float FBM(float3 p, inout float original)
	{
		//return tex3D(_MapNoise, (float3(p.x, p.z, p.y) / 100.0) - float3(0.5, 0.5, 0)).r;
		//p /= 50000.0;
		p /= 25000.0;
		float f = tex3Dlod(_MapNoise, (float4(p.x - 0.5, p.z - 0.5, p.y, 0))).r;
		//float f = 0;
		float3 pt = p;
		p.y = pt.z;
		p.z = pt.y;

		//p *= f + 63.0094439709
		//Scale of individual clouds
		float modScale = 10;
		p *= modScale;
		float gatherFactor = noise(p);
		//f += (((pow(noise(p), 0.1)) * 0.5));
		//original = f - (gatherFactor - 0.5);
		original = saturate(pow(gatherFactor, 10));
		f -= (gatherFactor - 0.5) * 2;
		return saturate(f / 5);
		/*
		float3 pt = p;
		p.y = pt.z;
		p.z = pt.y;

		p *= .25;
		//p *= 100;
		float f;

		f = 0.5000 * noise(p); p = p * 3.02; //p.y -= _Time.y*.2;
		//f += 0.2500 * noise(p); p = p * 3.03; //p.y += _Time.y*.06;
		//f += 0.1250 * noise(p); p = p * 3.01;
		//f += 0.0625  * noise(p); p = p * 3.03;
		//f += 0.03125  * noise(p); p = p * 3.02;
		//f += 0.015625 * noise(p);
		return f; */
	}

	float map(float3 p)
	{
		//p *= 0.002;
		float o = 0;
		float h = FBM(p + float3(0, 0, 0/*_Time.y*/), o);
		//return h - _CloudThickness - 0.5;
		return h - _CloudThickness - 0.5;
	}



	float map(float3 p, inout float original)
	{
		//p *= 0.002;
		float h = FBM(p + float3(0, 0, 0/*_Time.y*/), original);
		//return h - _CloudThickness - 0.5;
		return  h - _CloudThickness - 0.5;
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
		//o.uv = uv;

		o.uv = (uv - 0.5) * _FieldOfView;
		o.uv.x *= _AspectRatio;
		o.wPos = mul(unity_ObjectToWorld, vertex).xyz;
		o.cPos = _CameraPosition;

		if (!(unity_CameraProjection[0][2] < 0)) {
			_EyeOffset = -_EyeOffset;
		}

		o.cPos += _EyeOffset;

		//o.cPos += _EyeOffset;
		//o.cDir = normalize((_CameraUp * o.uv.y) + (_CameraRight * o.uv.x) + _CameraForward);
		//o.cDir = _LeftEyeVectorMatrix[(uv.x || uv.y) + (!uv.x && uv.y) + (uv.x && uv.y)].xyz;
		/*
		//uv.y = 1 - uv.y;

		if (unity_CameraProjection[0][2] < 0) {
		//Left
		o.cDir = normalize(_LeftEyeVectorMatrix[(uv.y * 2) + uv.x].xyz);

		}
		else {
		//Right
		o.cDir = normalize(_RightEyeVectorMatrix[(uv.y * 2) + uv.x].xyz);
		}*/

		//billinerp();
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

	uniform float _Steps;
	//static const int  _Steps = 50;
	static const int LightStepDiv = 5;
	//static const int  _Steps = 50;

	float getH(float3 p, inout float original, float StepVal, float i) {
		float h = map((p + float3(-_Time.y * 100, 0, 0)), original);
		//Distance smoothing from bottom 
		h += ((1.0 - (((float)i / 2.0) / ((float)StepVal))) / 2);
		h += (((((float)i) / ((float)StepVal))) / 4);
		original += ((1.0 - (((float)i / 2.0) / ((float)StepVal))) / 2);
		original += (((((float)i) / ((float)StepVal))) / 4);
		//shadow.y = max(-h, 0.0);
		//shadow.x += saturate(-h) / (float)StepVal;
		//shadowSum.y += shadow.y * (1 - shadowSum.y);
		//shadowSum.x -= shadow.x * (shadowSum.y) * shadowy;
		//shadowSum.x -= saturate(-h) * (1 - shadowSum.y);
		return clamp(h, -1, 0);
	}

	fixed4 raymarch(float3 position, float3 direction, in float depth)
	{
		float StepMod = 500.0 / (float)_Steps;
		//float3 sunDir = normalize(_SunPosition - position);
		//float brightness = ((max(dot(direction, _SunDir), 0.0) + 0.5) / 2);
		float brightness = 1 - ((dot(direction, _SunDir) + 1) / 2.0);
		//Old dot product light
		//float3 sunAmount = (_SunColor * (brightness)) + ((0.5 - brightness) * 2 * _AmbientLight );
		//float3 sunAmount = (_SunColor * (brightness) * 40);
		float3 sunAmount = (_SunColor * 0.5);
		//+((1 - brightness) * _AmbientLight);
		//Start pos
		//float beg = ((minHeight - position.y) / direction.y);
		//float end = ((maxHeight - position.y) / direction.y);
		



		//float3 p = float3(position.x + direction.x * beg, position.y + direction.y * minHeight, position.z + direction.z * beg);

		float3 lightPos = float3(0, 0, 0);
		//p += hash(p + float3(-_Time.y * 1000, 0, 0) / 100) * 500;


		float3 p = rayPlaneIntersection(position, direction, float3(0, minHeight, 0), float3(0, -1, 0));
		//float totalDist = distance(p, rayPlaneIntersection(position, direction, float3(0, maxHeight, 0), float3(0, -1, 0)));
		
		//float3 p = position;
		//direction = normalize(direction - position);
		float3 additional = direction * (((maxHeight - minHeight) / ((float)_Steps)));
		float3 additionalLight = float3(1, 1, 1) * (((maxHeight - minHeight) / ((float)_Steps / (float)LightStepDiv))) * 2.0;
		float difference = maxHeight - minHeight;
		float density = .0;
		float2 shadow;
		float2 shadowSum = float2(0, 0);
		float thickness = (_CloudThickness + 0.5);
		/*
		float totalDist = sqrt(pow((difference * direction.x / direction.z), 2)
			+ pow((difference * direction.y / direction.z), 2)
			+ pow(difference, 2));*/

		//float angle = atan(abs(normalize(direction)));
		float3 planeNormal = float3(0, minHeight, 0);
		float angle = acos(dot(normalize(planeNormal), normalize(direction)));
		float c = cross(planeNormal, direction);
		float totalDist = ((difference) / (sin(angle))) * sin(90) * 4;
		//float totalDist = difference;
		//p += additional;

		//float d = distance(position, p);
		//float d = distance(p, position) / direction.z;
		//float d = abs(p) - position;
		//float d = distance(mul((UNITY_MATRIX_MVP), p), mul((UNITY_MATRIX_MVP), position));
		//Individual cloud def
		clip(when_le(depth, 0) - 1);
		//Distance traveled through cloud volume
		float d = distance(p, position);
		float emptySpace = 1;
		//Starting position for calculating light

		//shadow.x = 1;
		shadow.x = 0.01;
		float thickestY = 0;
		float isBreak = 1;
		float lightSamples = 0;
		float3 lightSample1 = 0;
		float3 lightSample2 = 0;


		float2 test = float2(0.1, 0.1);
		//Light and shadow
		//float2 shadowSum2 = float2(100, 0);
		float2 shadowSum2 = float2(0, 0.2);

		//Vector pointing towards sun from point of light

		//clip(when_eq(float4(lightPos.x, lightPos.y, lightPos.z, 0), 0));
		float work = 0;

		for (int i = 0; i < _Steps; i++)
		{
			float shadowy = 1;// when_lt(shadowSum.y, 1);
							  //shadowy *= when_gt(1 - shadowSum.x, 0);
			shadowy *= when_lt(p.y, 1000);
			//shadowy *= when_lt(d, _MaxRenderDistance);
			if (shadowy < 1)
				break;
			//if (p.y >= end)
			//return float4(i / 50, 0, 0, 1);
			//shadowy *= when_gt(shadowSum.x, 0);
			//Used for distance field
			float original = 0;
			//return float4(0, 0, 0, 1);
			float h = getH(p, original, _Steps, i);
			//original *= thickness;
			//if(i > 10)
			//	return float4(original, original, original, 1);

			shadow.y = max(-h, 0.0);
			shadow.x += (max(-h, 0.0) / ((float)_Steps));
			//This is 0 when ANY cloud has been detected
			emptySpace = when_le(shadowSum.y, 0.5) && emptySpace;

			//Has there been a break in the clouds?
			isBreak = (when_le(shadow.y, 0) || isBreak) * emptySpace;
			//clip(-isBreak);
			//If there has been, is the current cloud thickness value higher than the old max?
			float newThickestY = isBreak && when_gt(shadow.y, thickestY);
			//When not in a cloud, move the lightpos forward
			//If it is, reset the thickest Y, light pos, and breaks
			thickestY -= thickestY * newThickestY;
			lightPos -= lightPos * newThickestY;
			lightSample1 -= lightSample1* newThickestY;
			lightSample2 -= lightSample2* newThickestY;

			isBreak = isBreak * !newThickestY;
			lightSamples += shadow.x * newThickestY * shadowy;
			//Is there a Y even thiccer than the thickest by a significant factor?
			thickestY += shadow.y * ((!emptySpace) * (when_eq(thickestY, 0)));
			//clip(-newThickestY);
			lightPos += p * (((newThickestY || (!emptySpace)) && (when_eq(float4(lightPos.x, lightPos.y, lightPos.z, 1), float4(0, 0, 0, 1))))) *  shadowy;
			lightSample1 += (!lightSample1.x) * lightPos * newThickestY * shadowy;
			lightSample2 += (lightSample1.x) * lightPos* newThickestY * shadowy;
			float lastShadowY = shadowSum.y;
			shadowSum.y += ((shadow.y) /* (1 - shadowSum.y)*/ /  _Steps) * (_Density / 4)  * StepMod * shadowy;
			//shadowSum.x -= saturate(-h) * (1 - shadowSum.y) * StepMod * shadowy;
			float dist = distance(position, p) / difference;
			//float3 newDist = (float3)direction * dist *  200; //* (float)(clamp((original) * MaxStepDist, MinStepDist, MaxStepDist)) * shadowy;
			float3 newDist = (float3)direction * 200.0 ;
			//float3 newDist = additional;
			d += length(newDist);
			p += direction * (totalDist / _Steps);
			//return distance(p, position) / 1000;
			work += 1.0 * shadowy;
			//return shadowSum.y;
			lightPos = p;
			for (int u = 0; u < (float)_Steps / (float)LightStepDiv; u++)
			{
				_SunDir = normalize(lightPos - _SunPos);
				float shadowy2 = 1;//= when_lt(shadowSum2.y, 1);
				shadowy2 = shadowy2 * when_lt(shadowSum2.x, 1);
				//if (shadowSum2.x >= 1)
				//	break;
				float original2 = 0;
				float t = getH(float3(lightPos.x, lightPos.y, lightPos.z), original2, (float)_Steps / (float)LightStepDiv, u);
				test.y = max(-t, 0.0);
				//test.x += (max(-t, 0.0) / ((float)_Steps ) * Density;// (float)LightStepDiv)) * Density;
				//shadowSum2.y += test.y * (1.0 - shadowSum2.y) * shadowy2;
				//Too aggressive? (works tho)
				//shadowSum2.x += shadow.x * (shadowSum2.y) * shadowy2;
				shadowSum2.x += (((max(-t, 0.0) / ((float)_Steps * (float)LightStepDiv))) * _Density * shadowy2) * brightness;
				lightPos -= ((additionalLight * _SunDir) / /*((float)_Steps * (float)LightStepDiv)) * u * 100*/5);
			}
			//shadowSum.x += (shadowSum2.x * (shadowSum.y - (shadow.y * (1 - shadowSum.y)))) / ((float)_Steps / (float)LightStepDiv);
			//Alpha premultiply

			float clampSum = 1 - saturate(shadowSum.y);
			float clampLastSum = saturate(lastShadowY);
			float carryTheTwo = shadowSum.x;
			//clampLastSum = 0;
			//shadowSum.x -= shadowSum.x * (shadowy);
			//&& when_gt(clampSum, 0) && when_lt(clampLastSum, 1)
			/**/
			shadowSum.x = (
				((carryTheTwo * clampLastSum) + ((shadowSum2.x * clampSum) * (1 - clampLastSum))) /
				(clampLastSum + (clampSum * (1 - clampLastSum))));
			// *
			//(shadowy);





			//shadowSum.x += shadowSum2.x;
			/*
			shadowSum.x += (
			((shadowSum2.x * clampSum) + ((carryTheTwo * clampLastSum) * (1 - clampSum))) /
			(clamp(clampSum, 0, 1) + (clampLastSum * (1 - clampSum)))) *
			(shadowy);*/
			/*
			shadowSum.x += (saturate((shadowSum.x * (1 - clamp(shadowSum.y, 0, 1))) +
			shadowSum2.x * (1 - clamp(shadowSum.y, 0, 1))) /
			((float)_Steps * (float)LightStepDiv / 100));*/
			/*
			shadowSum.x += (saturate((shadowSum.x * (1 - clamp(shadowSum.y, 0, 1))) +
			shadowSum2.x * (clamp(shadowSum.y, 0, 1))) /
			((float)_Steps * (float)LightStepDiv / 100));*/
		}
		//return float4(d / 10000, d / 10000, d / 10000, 1);
		//shadowSum.x = 0;
		//lightPos /= lightSamples;
		//shadowSum.x = 0;
		//shadowSum.x = (float)_Steps / (float)LightStepDiv;
		//shadowSum.x = 0.01;
		//shadowSum.x = (float)_Steps;
		/*
		float2 test = float2(0, 0);
		//Light and shadow
		//float2 shadowSum2 = float2(100, 0);
		float2 shadowSum2 = float2(0, 0);

		//Vector pointing towards sun from point of light
		_SunDir = normalize(lightPos - _SunPos);
		//clip(when_eq(float4(lightPos.x, lightPos.y, lightPos.z, 0), 0));
		additionalLight *= _SunDir;

		for (int u = 0; u < (float)_Steps / (float)LightStepDiv; u++)
		{

		float shadowy2 = 1;//= when_lt(shadowSum2.y, 1);
		shadowy2 = shadowy2 * when_lt(shadowSum2.x, 1);
		//if (shadowSum2.x >= 1)
		//	break;
		float t = getH(float3(lightPos.x, lightPos.y, lightPos.z), (float)_Steps / (float)LightStepDiv, u);
		test.y = max(-t, 0.0);
		//test.x += (max(-t, 0.0) / ((float)_Steps ) * Density;// (float)LightStepDiv)) * Density;
		//shadowSum2.y += test.y * (1.0 - shadowSum2.y) * shadowy2;
		//Too aggressive? (works tho)
		//shadowSum2.x += shadow.x * (shadowSum2.y) * shadowy2;
		shadowSum2.x += (max(-t, 0.0) / ((float)_Steps/ (float)LightStepDiv)) * _Density;
		lightPos -= (additionalLight / 5);// * u;
		}*/
		//return shadowSum2.x;
		//shadowSum.y = 0;
		work /=  _Steps;
		//return float4(shadowSum.x, shadowSum.x, shadowSum.x, 1);

		//shadowSum.x = shadowSum2.x;
		//shadowSum.x *= max((float)dot(direction, -_SunDir), 0.0) /100;
		//shadowSum.y = min(shadowSum.y, 1);
		//return float4(work, work, work, 1);
		//return float4(shadowSum.y, shadowSum.y, shadowSum.y, 1) / 1;
		shadowSum.y = saturate(shadowSum.y);
		shadowSum.x = saturate(shadowSum.x);



		//tex2D(_MapFracPow, float2
		float3 clouds = lerp(sunAmount, 0, pow(shadowSum.x, 0.4));
		//return float4(shadowSum.x, shadowSum.x, shadowSum.x, 2) / 2;
		//
		//float3 clouds = lerp(sunAmount, 0,  (float)tex2D(_MapFracPow, float2(0.4, shadowSum.x)).r/*pow((shadowSum.x), (0.4))*/ * 10.0);
		clouds += lerp(_AmbientLight, 0, pow(1 - shadowSum.x, 1));
		//float3 clouds = 1;
		float3 cMin = min(clouds, 1.0);
		float4 sky2 = lerp(float4(0, 0, 0, 0), float4(cMin.x, cMin.y, cMin.z, 1), shadowSum.y);
		return clamp(float4(sky2.x, sky2.y, sky2.z, sky2.a), 0.0, 1.0);
	}


	uniform sampler2D _CameraDepthTexture;

	sampler2D _CurrentDepth;

	struct fragOut {
		half4 color : COLOR;
		float depth : DEPTH;
	};

	//fragOut frag(v2f i, UNITY_VPOS_TYPE screenPos : VPOS) : SV_Target{
	fragOut frag(v2f i) {
		//clip(i.cDir.y);

		fragOut o;
		//i.cDir.x = lerp(_LeftEyeVectorMatrix[0].x, _LeftEyeVectorMatrix[1].x, i.uv.x);
		//i/.cDir.y = lerp(_LeftEyeVectorMatrix[0].y, _LeftEyeVectorMatrix[2].y, i.uv.y);
		//i.cDir = normalize((_CameraUp * i.uv.y) + (_CameraRight * i.uv.x) + _CameraForward);
		//float depth = LinearEyeDepth(tex2D(_CameraDepthTexture, i.uv).r);
		float2 auv = (i.uv) / _FieldOfView;
		//float2 auv = i.uv;
		auv.x /= _AspectRatio;
		auv.y += 0.5;
		auv.x += 0.5;
		float depth = /*LinearEyeDepth(tex2D(_CameraDepthTexture, auv).r)*/tex2D(_CameraDepthTexture, auv).r;
		//clip(1 - depth  *100);
		//float depth = 0;
		auv.y = 1 - auv.y;

		if (unity_CameraProjection[0][2] > 0) {
			i.cDir = normalize(bilerpC(_LeftEyeVectorMatrix[0],
				_LeftEyeVectorMatrix[1],
				_LeftEyeVectorMatrix[2],
				_LeftEyeVectorMatrix[3],
				auv).xyz);
		}
		else {
			i.cDir = normalize(bilerpC(_RightEyeVectorMatrix[0],
				_RightEyeVectorMatrix[1],
				_RightEyeVectorMatrix[2],
				_RightEyeVectorMatrix[3],
				auv).xyz);
		}
		depth *= length(i.cDir.xyz);
		o.color = raymarch(i.cPos, i.cDir, depth);

		o.depth = depth;
		return o;
	}
	ENDCG
	}
	}
}