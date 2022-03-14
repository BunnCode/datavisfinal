// Upgrade NOTE: replaced '_Object2World' with 'unity_ObjectToWorld'

// Upgrade NOTE: replaced '_Object2World' with 'unity_ObjectToWorld'

// Upgrade NOTE: replaced '_Object2World' with 'unity_ObjectToWorld'

Shader "VolumetricShaders/DensityRenderer" {
	Properties{
		_Color("color", Color) = (0, 0, 0, 1)
		_Radius("radius", Float) = 4
		_CloudThickness("Thickness", range(-0.5, 0.5)) = 0.0
		_MaxRenderDistance("Render Distance", range(0, 20)) = 4
		_Steps("Steps", range(0, 50)) = 50
		//_MapNoise("MapNoise", 3D) = "white"{}
		_MapRand("MapRandom", 2D) = "white"{}
		_AmbientLight("Ambient Light", Color) = (0.2, 0, 0, 1)
		_Density("Density", Float) = 4

		_Center("Center", Vector) = (0,0,0,0)
		_AABBMin("Bounding box min", Vector) = (1, 1, 1)
		_AABBMax("Bounding box max", Vector) = (1, 1, 1)

		_Scale("Scale", Vector) = (1, 1, 1)

		_SunColor("Sun Color", Color) = (1, 1, 1, 1)
		_DensityTexture("Density Tex", 3D) = "white"{}
		_HeatmapTexture("Heatmap Tex", 2D) = "white"{}
			//_lightPosition("LightPosition", Vector) = (0,0,0,0)
	}
		SubShader{
		Pass{
				//Blend SrcAlpha OneMinusSrcAlpha
				Blend SrcAlpha Zero
				ZWrite Off
				ZTest LEqual
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

		//Test orb
		uniform float4 _Center;
		uniform float4 _Scale;
		uniform float _Radius;

		uniform float4 _Color;
		uniform float3 _SunColor = float3(1.0, 1.0, 0.9);
		uniform float4 _AmbientLight;
		uniform float3 _SunPos = float3(0, 0, 0);
		uniform float3 _SunDir = float3(0, 0, 0);

		uniform float _MaxRenderDistance;
		uniform sampler3D _MapNoise;
		uniform float4 _MapNoise_TexelSize;

		uniform sampler3D _DensityTexture;
		uniform float4 _DensityTexture_TexelSize;
		
		uniform float3 _AABBMin;
		uniform float3 _AABBMax;

		uniform sampler2D _HeatmapTexture;

		uniform sampler2D _MapRand;
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
			o.uv = (uv - 0.5) * _FieldOfView;
			o.uv.x *= _AspectRatio;
			o.wPos = mul(unity_ObjectToWorld, vertex).xyz;
			o.cPos = _CameraPosition;

			if (!(unity_CameraProjection[0][2] < 0)) {
				_EyeOffset = -_EyeOffset;
			}

			o.cPos += _EyeOffset;

			outpos = UnityObjectToClipPos(vertex);
			return o;
		}

		//modified from https://gdbooks.gitbooks.io/3dcollisions/content/Chapter3/raycast_aabb.html
		//axis-aligned bounding box
		struct AABB {
			float3 min;
			float3 max;
		};
		//Ray
		struct Ray {
			float3 origin;
			float3 dir;
		};

		//returns a float2; x is the nearest collision, y is the furthest.
		float2 AABBRaycast(Ray ray, AABB aabb) {
			float t1 = (aabb.min.x - ray.origin.x) / ray.dir.x;
			float t2 = (aabb.max.x - ray.origin.x) / ray.dir.x;
			float t3 = (aabb.min.y - ray.origin.y) / ray.dir.y;
			float t4 = (aabb.max.y - ray.origin.y) / ray.dir.y;
			float t5 = (aabb.min.z - ray.origin.z) / ray.dir.z;
			float t6 = (aabb.max.z - ray.origin.z) / ray.dir.z;

			float tmin = max(max(min(t1, t2), min(t3, t4)), min(t5, t6));
			float tmax = min(min(max(t1, t2), max(t3, t4)), max(t5, t6));

			//todo: Is this causing branching?? Try to make it an arithmetic or bitmask op asap

			// if tmax < 0, ray (line) is intersecting AABB, but whole AABB is behing us
			if (tmax < 0) {
				return float2(-1, -1);
			}

			// if tmin > tmax, ray doesn't intersect AABB
			if (tmin > tmax) {
				return float2(-1, -1);
			}
			
			if (tmin < 0) {
				return float2(tmax, tmin);
			}
			return float2(tmin, tmax);
		}
		
		float3 colorFromScalar(float scalar) {
			return tex2D(_HeatmapTexture, float2(scalar, 0));
		}

		//Sample density data 
		float sampleDensity(float3 p, float3 texOffset) {
			float h = tex3Dlod(_DensityTexture, float4(((p - _Center) / _Scale) + texOffset, 0) ).r;
			return h;
		}

		float sampleDensity(float3 p) {
			return sampleDensity(p, float3(0, 0, 0));
		}

		//Calculate normal (currently unused)
		float3 normal(float3 p)
		{
			const float eps = 0.01;
			return normalize
			(float3
				(sampleDensity(p + float3(eps, 0, 0)) - sampleDensity(p - float3(eps, 0, 0)),
					sampleDensity(p + float3(0, eps, 0)) - sampleDensity(p - float3(0, eps, 0)),
					sampleDensity(p + float3(0, 0, eps)) - sampleDensity(p - float3(0, 0, eps))
					)
			);
		}

#define STEPS 100 //arbitrary
		
		fixed4 raymarch(float3 position, const float3 direction, in float depth)
		{
			Ray ray = { position, direction };
			AABB box = { _AABBMax, _AABBMin };

			//Check if ray hit rendering volume. x component is closest, y is furthest intersection
			float2 hitdata = AABBRaycast(ray, box);

			clip(hitdata.x);//Didn't hit AABB? Bounce, yer done.
			float3 p = position + (direction * hitdata.x);
			//depth of the ray intersection w the AABB
			float volumeDepth = abs(hitdata.x - hitdata.y);

			//Distance to step by 
			const float stepDistance = volumeDepth / (float)STEPS;
			//Offset for the texture (to center it)
			const float3 offset = float3(0.5, 0.5, 0.5);

			//Amount to step by each step
			const float3 additional = float3(direction.x, direction.y, direction.z) * stepDistance;
			//Output values
			float densityOut = 0;
			float3 colorOut = 0;
			
			//Raymarch
			[unroll(STEPS)]
			for (int i = 0; i < STEPS; i++){
				float h = sampleDensity(p, offset);
				float sliceDensity = (h * _Density) / STEPS;
				densityOut += sliceDensity;
				//premultiply color
				colorOut += (colorFromScalar(h) * sliceDensity);
				//March ray forward
				p += additional;
			}
			return float4(colorOut.r, colorOut.g, colorOut.b, densityOut);
		}


		uniform sampler2D _CameraDepthTexture;

		sampler2D _CurrentDepth;

		struct fragOut {
			half4 color : COLOR;
			float depth : DEPTH;
		};

		//fragOut frag(v2f i, UNITY_VPOS_TYPE screenPos : VPOS) : SV_Target{
		fragOut frag(v2f i) {
			fragOut o;
			float2 auv = (i.uv) / _FieldOfView;
			auv.x /= _AspectRatio;
			auv.y += 0.5;
			auv.x += 0.5;
			float depth = tex2D(_CameraDepthTexture, auv).r;
			//clip(1 - depth  *100);
			//float depth = 0;
			auv.y = 1 - auv.y;

			if (unity_CameraProjection[0][2] < 0) {
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