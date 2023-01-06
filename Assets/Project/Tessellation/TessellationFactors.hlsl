// MIT License

// Copyright (c) 2021 NedMakesGames

// Permission is hereby granted, free of charge, to any person obtaining a copy
// of this software and associated documentation files(the "Software"), to deal
// in the Software without restriction, including without limitation the rights
// to use, copy, modify, merge, publish, distribute, sublicense, and / or sell
// copies of the Software, and to permit persons to whom the Software is
// furnished to do so, subject to the following conditions :

// The above copyright notice and this permission notice shall be included in all
// copies or substantial portions of the Software.

// THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
// IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
// FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT.IN NO EVENT SHALL THE
// AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
// LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
// OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
// SOFTWARE.

#ifndef TESSELLATION_FACTORS_INCLUDED
#define TESSELLATION_FACTORS_INCLUDED

#include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/Lighting.hlsl"



#include "Wave.hlsl"
#include "WaterSurface.hlsl"

struct Attributes
{
    float3 positionOS : POSITION;
    float2 uv : TEXCOORD0;
    UNITY_VERTEX_INPUT_INSTANCE_ID
};

struct TessellationFactors {
    float edge[3] : SV_TessFactor;
    float inside : SV_InsideTessFactor;
};

struct TessellationControlPoint {
    float3 positionWS : INTERNALTESSPOS;
    float4 positionCS : SV_POSITION;
    float2 uv : TEXCOORD0;
    UNITY_VERTEX_INPUT_INSTANCE_ID
};

struct Interpolators {
    float2 uv                       : TEXCOORD0;
    float3 normalWS                 : TEXCOORD1;
    float3 positionWS               : TEXCOORD2;
    float4 screenPos                : TEXCOORD3;
    float maxWaveHeight             : TEXCOORD4;
    float3 tangentWS                : TEXCOORD5;
    float3 binormalWS                : TEXCOORD6;
    float4 positionCS               : SV_POSITION;
    UNITY_VERTEX_INPUT_INSTANCE_ID
    UNITY_VERTEX_OUTPUT_STEREO
};

CBUFFER_START(UnityPerMaterial)
    float3 _FactorEdge1;
    float _Tolerance;
    float _Bias;
    float _TessellationFactor;
    float _FactorInside;
    
    float3 _W1_Prop_Sharpness_WaveLength_Speed;
    float2 _W1_Direction;
    float3 _W2_Prop_Sharpness_WaveLength_Speed;
    float2 _W2_Direction;
    float3 _W3_Prop_Sharpness_WaveLength_Speed;
    float2 _W3_Direction;
    
    float _Foam_Noise_Scale;
    float _Foam_Step;
    float _Foam_Step_Smooth;
    sampler2D _Foam_Texture;
    float _Foam_Texture_Scale;
    float _Foam_Texture_Step;
    float _Foam_Texture_Smooth;
    float _Object_Foam_Depth;
    float _Object_Foam_Fac;
    
    sampler2D _Normal_Map;
    float _Normal_Map_Scale;
    float _Normal_Map_Speed;
    float _Normal_Map_Strength;
    
CBUFFER_END

float3 GetViewDirectionFromPosition(float3 positionWS) {
    return normalize(GetCameraPositionWS() - positionWS);
}

float4 GetShadowCoord(float3 positionWS, float4 positionCS) {
    // Calculate the shadow coordinate depending on the type of shadows currently in use
#if SHADOWS_SCREEN
    return ComputeScreenPos(positionCS);
#else
    return TransformWorldToShadowCoord(positionWS);
#endif
}

TessellationControlPoint Vertex(Attributes input) {
    TessellationControlPoint output;

    UNITY_SETUP_INSTANCE_ID(input);
    UNITY_TRANSFER_INSTANCE_ID(input, output);

    VertexPositionInputs posnInputs = GetVertexPositionInputs(input.positionOS);

    output.positionCS = posnInputs.positionCS;
    output.positionWS = posnInputs.positionWS;
    output.uv = input.uv;
        
    return output;
}

    // Calculate the tessellation factor for an edge
    float EdgeTessellationFactor(float scale, float bias, float3 p0PositionWS, float3 p1PositionWS)
    {
        float factor = scale;

        return max(1, factor + bias);
    }
    
    // Returns true if the point is outside the bounds set by lower and higher
    bool IsOutOfBounds(float3 p, float3 lower, float3 higher)
    {
        return p.x < lower.x || p.x > higher.x || p.y < lower.y || p.y > higher.y || p.z < lower.z || p.z > higher.z;
    }

// Returns true if the given vertex is outside the camera fustum and should be culled
    bool IsPointOutOfFrustum(float4 positionCS, float tolerance)
    {
        float3 culling = positionCS.xyz;
        float w = positionCS.w;
    // UNITY_RAW_FAR_CLIP_VALUE is either 0 or 1, depending on graphics API
    // Most use 0, however OpenGL uses 1
        float3 lowerBounds = float3(-w - tolerance, -w - tolerance, -w * UNITY_RAW_FAR_CLIP_VALUE - tolerance);
        float3 higherBounds = float3(w + tolerance, w + tolerance, w + tolerance);
        return IsOutOfBounds(culling, lowerBounds, higherBounds);
    }
    
    
    // Returns true if it should be clipped due to frustum or winding culling
    bool ShouldClipPatch(float4 p0PositionCS, float4 p1PositionCS, float4 p2PositionCS)
    {
        return IsPointOutOfFrustum(p0PositionCS, _Tolerance) &&
        IsPointOutOfFrustum(p1PositionCS, _Tolerance) &&
        IsPointOutOfFrustum(p2PositionCS, _Tolerance);

    }

   
    // Calculate the tessellation factor for an edge
    float EdgeTessellationFactor(float3 p0PositionWS, float3 p1PositionWS)
    {
        float distanceToCamera = distance(GetCameraPositionWS(), (p0PositionWS + p1PositionWS) * 0.5);
        float length = distance(p0PositionWS, p1PositionWS);
        float localScale = 1;
        
        #if  _SCALABLETESSELATION_ON
            localScale =  GetObjectScaleAverage();
        #endif
        
        float factor = length * localScale / (_TessellationFactor * distanceToCamera * distanceToCamera);

        return max(1, factor + _Bias);
    }
// The patch constant function runs once per triangle, or "patch"
// It runs in parallel to the hull function
TessellationFactors PatchConstantFunction(
    InputPatch<TessellationControlPoint, 3> patch) {
    UNITY_SETUP_INSTANCE_ID(patch[0]); // Set up instancing
    // Calculate tessellation factors
        
    TessellationFactors f;
        if (ShouldClipPatch(patch[0].positionCS, patch[1].positionCS, patch[2].positionCS))
        {
            f.edge[0] = f.edge[1] = f.edge[2] = f.inside = 0; // Cull the patch
        }
        else
        {
            f.edge[0] = EdgeTessellationFactor(patch[1].positionWS, patch[2].positionWS);
            f.edge[1] = EdgeTessellationFactor(patch[2].positionWS, patch[0].positionWS);
            f.edge[2] = EdgeTessellationFactor(patch[0].positionWS, patch[1].positionWS);
            f.inside = (f.edge[0] + f.edge[1] + f.edge[2]) / 3.0;
        }

    return f;
}

// The hull function runs once per vertex. You can use it to modify vertex
// data based on values in the entire triangle
[domain("tri")] // Signal we're inputting triangles
[outputcontrolpoints(3)] // Triangles have three points
[outputtopology("triangle_cw")] // Signal we're outputting triangles
[patchconstantfunc("PatchConstantFunction")] // Register the patch constant function
// Select a partitioning mode based on keywords
#if defined(_PARTITIONING_INTEGER)
[partitioning("integer")]
#elif defined(_PARTITIONING_FRAC_EVEN)
[partitioning("fractional_even")]
#elif defined(_PARTITIONING_FRAC_ODD)
[partitioning("fractional_odd")]
#elif defined(_PARTITIONING_POW2)
[partitioning("pow2")]
#else 
[partitioning("fractional_odd")]
#endif
TessellationControlPoint Hull(
    InputPatch<TessellationControlPoint, 3> patch, // Input triangle
    uint id : SV_OutputControlPointID) { // Vertex index on the triangle

    return patch[id];
}

// Call this macro to interpolate between a triangle patch, passing the field name
#define BARYCENTRIC_INTERPOLATE(fieldName) \
		patch[0].fieldName * barycentricCoordinates.x + \
		patch[1].fieldName * barycentricCoordinates.y + \
		patch[2].fieldName * barycentricCoordinates.z

// The domain function runs once per vertex in the final, tessellated mesh
// Use it to reposition vertices and prepare for the fragment stage
[domain("tri")] // Signal we're inputting triangles
Interpolators Domain(
    TessellationFactors factors, // The output of the patch constant function
    OutputPatch<TessellationControlPoint, 3> patch, // The Input triangle
    float3 barycentricCoordinates : SV_DomainLocation) { // The barycentric coordinates of the vertex on the triangle

    Interpolators output;

    // Setup instancing and stereo support (for VR)
    UNITY_SETUP_INSTANCE_ID(patch[0]);
    UNITY_TRANSFER_INSTANCE_ID(patch[0], output);
    UNITY_INITIALIZE_VERTEX_OUTPUT_STEREO(output);

    
        float3 positionWS = BARYCENTRIC_INTERPOLATE(positionWS);
        float3 neighbor1New, neighbor2New;
        
        WavePos_float((positionWS + float3(0.1, 0.0, 0.0)),
            _W1_Prop_Sharpness_WaveLength_Speed, _W1_Direction,
            _W2_Prop_Sharpness_WaveLength_Speed, _W2_Direction,
            _W3_Prop_Sharpness_WaveLength_Speed, _W3_Direction,
            _Time.y, neighbor1New);
        
        WavePos_float((positionWS + float3(0.0, 0.0, 0.1)),
            _W1_Prop_Sharpness_WaveLength_Speed, _W1_Direction,
            _W2_Prop_Sharpness_WaveLength_Speed, _W2_Direction,
            _W3_Prop_Sharpness_WaveLength_Speed, _W3_Direction,
            _Time.y, neighbor2New);
        
        float3 wavedPosWS;
        float maxHeight;
        WavePos_float((positionWS),
            _W1_Prop_Sharpness_WaveLength_Speed, _W1_Direction,
            _W2_Prop_Sharpness_WaveLength_Speed, _W2_Direction,
            _W3_Prop_Sharpness_WaveLength_Speed, _W3_Direction,
            _Time.y, wavedPosWS, maxHeight);
    
        float3 wavedNormal =-1.0 * (cross(normalize((neighbor1New - wavedPosWS)), normalize((neighbor2New - wavedPosWS))));
        
        output.uv = BARYCENTRIC_INTERPOLATE(uv);
        output.maxWaveHeight = maxHeight;
        output.positionCS = TransformWorldToHClip(wavedPosWS);
        output.normalWS = wavedNormal;
        output.tangentWS = cross(wavedNormal, float3(1, -0.2, 0)); // TODO: Give a local dir
        output.binormalWS = cross(wavedNormal, output.tangentWS);
        output.positionWS = wavedPosWS;
        output.screenPos = ComputeScreenPos(output.positionCS);
        //output.positionVS = TransformWorldToView(wavedPosWS);

    return output;
}

float4 Fragment(Interpolators input) : SV_Target{
    UNITY_SETUP_INSTANCE_ID(input);
    UNITY_SETUP_STEREO_EYE_INDEX_POST_VERTEX(input);

    // Fill the various lighting and surface data structures for the PBR algorithm
    InputData lightingInput = (InputData)0; // Found in URP/Input.hlsl
    lightingInput.positionWS = input.positionWS;
        lightingInput.normalWS = CalcNormal(input.normalWS, input.tangentWS, input.binormalWS,
                                    _Normal_Map, _Normal_Map_Speed, _Normal_Map_Scale, _Normal_Map_Strength,
                                        input.uv); /*input.normalWS;*/
    lightingInput.viewDirectionWS = GetViewDirectionFromPosition(lightingInput.positionWS);
    lightingInput.shadowCoord = GetShadowCoord(lightingInput.positionWS, input.positionCS);
    lightingInput.normalizedScreenSpaceUV = GetNormalizedScreenSpaceUV(input.positionCS);

        float depth = GetObjectDepth(input.screenPos);
        float foam = GetFoam(_Foam_Noise_Scale, _Foam_Step, input.maxWaveHeight, _Foam_Step_Smooth, _Foam_Texture,
                            _Foam_Texture_Scale, _Foam_Texture_Step, _Foam_Texture_Smooth,
                            _Object_Foam_Depth, _Object_Foam_Fac, input.uv, GetObjectDepth(input.screenPos));
        
        //return float4(foam, foam, foam, 1.0);
        
        
        SurfaceData surface = (SurfaceData) 0; // Found in URP/SurfaceData.hlsl
        surface.albedo = 0;
        surface.alpha = 1.0;
        surface.metallic = 0;
        surface.smoothness = 1.0;
        surface.normalTS = float3(0, 0, 1);
        //surface.normalTS = GetTangentNormal(_Normal_Map, _Normal_Map_Speed, _Normal_Map_Scale, _Normal_Map_Strength, input.uv);
        surface.occlusion = 1;

        
        return UniversalFragmentPBR(lightingInput, surface);
}

#endif