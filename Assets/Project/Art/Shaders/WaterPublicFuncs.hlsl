half3 GetObjectScale()
{
    return half3(
    length(unity_ObjectToWorld._m00_m10_m20),
    length(unity_ObjectToWorld._m01_m11_m21),
    length(unity_ObjectToWorld._m02_m12_m22));
};

half GetObjectScaleAverage()
{

    half3 scale = GetObjectScale();
    return scale.x + scale.y + scale.z / 3;
};

float2 unity_gradientNoise_dir(float2 p)
{
    p = p % 289;
    float x = (34 * p.x + 1) * p.x % 289 + p.y;
    x = (34 * x + 1) * x % 289;
    x = frac(x / 41) * 2 - 1;
    return normalize(float2(x - floor(x + 0.5), abs(x) - 0.5));
}

float unity_gradientNoise(float2 p)
{
    float2 ip = floor(p);
    float2 fp = frac(p);
    float d00 = dot(unity_gradientNoise_dir(ip), fp);
    float d01 = dot(unity_gradientNoise_dir(ip + float2(0, 1)), fp - float2(0, 1));
    float d10 = dot(unity_gradientNoise_dir(ip + float2(1, 0)), fp - float2(1, 0));
    float d11 = dot(unity_gradientNoise_dir(ip + float2(1, 1)), fp - float2(1, 1));
    fp = fp * fp * fp * (fp * (fp * 6 - 15) + 10);
    return lerp(lerp(d00, d01, fp.y), lerp(d10, d11, fp.y), fp.x);
}

float Unity_GradientNoise(float2 UV, float Scale)
{
    return unity_gradientNoise(UV * Scale) + 0.5;
}