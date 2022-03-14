float4 when_eq(float4 x, float4 y) {
  return 1.0 - abs(sign(x - y));
}

float4 when_neq(float4 x, float4 y) {
  return abs(sign(x - y));
}

float4 when_gt(float4 x, float4 y) {
  return max(sign(x - y), 0.0);
}

float4 when_lt(float4 x, float4 y) {
  return max(sign(y - x), 0.0);
}

float4 when_ge(float4 x, float4 y) {
  return 1.0 - when_lt(x, y);
}

float4 when_le(float4 x, float4 y) {
  return 1.0 - when_gt(x, y);
}

float4x4 inverse(float4x4 input)
{
#define minor(a,b,c) determinant(float3x3(input.a, input.b, input.c))
	//determinant(float3x3(input._22_23_23, input._32_33_34, input._42_43_44))

	float4x4 cofactors = float4x4(
		minor(_22_23_24, _32_33_34, _42_43_44),
		-minor(_21_23_24, _31_33_34, _41_43_44),
		minor(_21_22_24, _31_32_34, _41_42_44),
		-minor(_21_22_23, _31_32_33, _41_42_43),

		-minor(_12_13_14, _32_33_34, _42_43_44),
		minor(_11_13_14, _31_33_34, _41_43_44),
		-minor(_11_12_14, _31_32_34, _41_42_44),
		minor(_11_12_13, _31_32_33, _41_42_43),

		minor(_12_13_14, _22_23_24, _42_43_44),
		-minor(_11_13_14, _21_23_24, _41_43_44),
		minor(_11_12_14, _21_22_24, _41_42_44),
		-minor(_11_12_13, _21_22_23, _41_42_43),

		-minor(_12_13_14, _22_23_24, _32_33_34),
		minor(_11_13_14, _21_23_24, _31_33_34),
		-minor(_11_12_14, _21_22_24, _31_32_34),
		minor(_11_12_13, _21_22_23, _31_32_33)
		);
#undef minor
	return transpose(cofactors) / determinant(input);
}

float3 rayPlaneIntersection(float3 startPos, float3 dir, float3 planePoint, float3 planeNormal) {
	float3 planeRelativeNormal = planePoint + planeNormal;
	float d = -dot(planePoint, planeNormal);
	return((-(dot(startPos, planeNormal) + d) / dot(dir, planeNormal)) * dir) + startPos;
}

float4 bilerpC(float4 val1, float4 val2, float4 val3, float4 val4, float2 p) {
	return (p.x*val2 + (1 - p.x)*val1 + p.x*val4 + (1 - p.x)*val3 + p.y*val3 + (1 - p.y)*val1 + p.y*val4 + (1 - p.y) * val2) / 4.0;
}