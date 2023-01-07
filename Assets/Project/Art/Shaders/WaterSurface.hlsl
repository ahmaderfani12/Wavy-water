#include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/DeclareDepthTexture.hlsl"
#include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/DeclareOpaqueTexture.hlsl"
#include "WaterPublicFuncs.hlsl"


float GetObjectDepthNoise(float4 screenPos,float3 normal, float noiseStrength)
{
    float4 screenPosNoise = float4(lerp(float3(0, 0, 0), normal, noiseStrength), 0) + screenPos;
    float rawDepth = SampleSceneDepth(screenPosNoise.xy / screenPosNoise.w);
    float sceneEyeDepth = LinearEyeDepth(rawDepth, _ZBufferParams);
    return sceneEyeDepth - screenPosNoise.w;
}

float GetObjectDepth(float4 screenPos)
{
    float rawDepth = SampleSceneDepth(screenPos.xy / screenPos.w);
    float sceneEyeDepth = LinearEyeDepth(rawDepth, _ZBufferParams);
    return sceneEyeDepth - screenPos.w;
}

float GetFoam(float foamNoiseScale, float step, float foamStep, float foamStepSmooth,
            sampler2D foamTexture,float foamTextureScale,float foamTextureStep, float foamTextureSmooth,
            float objectFoamFac1, float objectFoamFac2,float2 uv, float depthIn)
{
    
    // Noise 1 (Better to use texture here too)
    float desiredDepth = 1.0 -  (1.0 - saturate(depthIn * objectFoamFac1)) * objectFoamFac2;
    float noise = Unity_GradientNoise(_Time.x/10 + uv, foamNoiseScale);
    
    noise = noise + desiredDepth + step;
    
    noise =1.0 -  smoothstep(foamStep, foamStep + foamStepSmooth,noise);

    // Noise2
    float noiseTexture = tex2D(foamTexture, uv*foamTextureScale).x;
    noiseTexture = 1.0 - smoothstep(foamTextureStep, foamTextureStep + foamTextureSmooth, noiseTexture);
    
    return noise * noiseTexture;    
}

float3 CalcNormal(float3 normalWS,float3 tangentWS,float3 binormalWS,sampler2D normalMap, float speed, float scale, float strength,float2 uv)
{
    float offsetSpeed = _Time.y * speed;
    float3x3 TBN_matrix = float3x3(tangentWS, binormalWS, normalWS);
    
    float4 normal1 = tex2D(normalMap, offsetSpeed + uv * scale);
    float4 normal2 = tex2D(normalMap, -offsetSpeed + uv * scale);
    
    float3 normalCompressed1 = UnpackNormal(normal1);
    float3 normalCompressed2 = UnpackNormal(normal2);
    
    float3 normalTangent1 = lerp(normalWS, normalize(mul(normalCompressed1, TBN_matrix)), strength);
    float3 normalTangent2 = lerp(normalWS, normalize(mul(normalCompressed2, TBN_matrix)), strength);
    
    // Blend two normals
    return normalize(float3(normalTangent1.rg + normalTangent2.rg, normalTangent1.b * normalTangent2.b));

}

float3 WaterColor(float4 color, float depth, float transparentDepth, float transparentDepthPow, float3 normal, float4 screenPos, float noiseStrength)
{
    
    float depthMask = saturate(pow(depth * transparentDepth, transparentDepthPow));
    
    float4 screenPosNoise = float4(lerp(float3(0, 0, 0), normal, noiseStrength), 0) + screenPos;
    float3 underWaterColor = SampleSceneColor(screenPosNoise.xy / screenPosNoise.w).xyz;
    
    //return SampleSceneColor(screenPos.xy/screenPos.w);
    
    return lerp(underWaterColor, color.rgb, depthMask);

}