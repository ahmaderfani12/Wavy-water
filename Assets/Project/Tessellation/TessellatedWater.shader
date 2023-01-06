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


Shader "TessellatedWater" {
    Properties{

        Normal_Categoty("# Normal",float) = 0
        _Normal_Map("Normal Map &",2D)="white"{}
        _Normal_Map_Scale("Normal Map Scale",Range(0,15)) = 1
        _Normal_Map_Speed("Normal Map Speed",Range(0.01,0.2)) = 1.0
        _Normal_Map_Strength("Normal Map Strength", Range(0,1)) = 1

        Tessellation_Categoty("# Tessellation",float) = 0
        [KeywordEnum(INTEGER, FRAC_EVEN, FRAC_ODD, POW2)] _PARTITIONING("Partition algoritm", Float) = 0
        _Tolerance("Culling Tolerance", Range(0.0,1.5)) = 0.6
        _Bias("Bias", Float) = 0
        _TessellationFactor("Tessellation Factor", Range(0.0,0.1)) = 0
        [Toggle] _ScalableTesselation("Scalable Tesselation", float) = 0

        Vertex_Waves_Categoty("# Vertex Waves",float) = 0
        _W1_Prop_Sharpness_WaveLength_Speed("W1 Prop (Sharpness, WaveLength, Speed) &",vector) = (0.53,1,0.61,0.0)
        _W1_Direction("W1Direction",vector) = (0.08,-0.98,0.0,0.0)
        _W2_Prop_Sharpness_WaveLength_Speed("W2 Prop (Sharpness, WaveLength, Speed) &",vector) = (0.38,0.17,0.41,0.0)
        _W2_Direction("W2Direction",vector) = (0.45,1.95,0.0,0.0)
        _W3_Prop_Sharpness_WaveLength_Speed("W3 Prop (Sharpness, WaveLength, Speed) &",vector) = (0.40,0.50,0.24,0.0)
        _W3_Direction("W2 Direction",vector) = (-0.9,0.5,0.0,0.0)

        Foam_Categoty("# Foam",float) = 0
        _Foam_Noise_Scale("Foam Noise Scale",Range(0,130)) = 100
        _Foam_Step("Foam Step",Range(0,10)) = 5.25
        _Foam_Step_Smooth("Foam Step Smooth",Range(0,1)) = 0.357
        _Foam_Texture("Foam Texture &",2D) = "white"{}
        _Foam_Texture_Scale("Foam Texture Scale",Range(0,10)) = 6.7
        _Foam_Texture_Step("Foam Texture Step",Range(0,1)) = 0
        _Foam_Texture_Smooth("Foam Texture Smooth",Range(0,1)) = 0.241

        ObjectFoam_Categoty("## Object Foam",float) = 0
        _Object_Foam_Depth("Object Foam Depth",Range(0.01,2)) = 1.06
        _Object_Foam_Fac("Object Foam Fac",Range(0,4)) = 2.32
    }
    SubShader{
        Tags{"RenderType" = "Transparent" "Queue"="Transparent" "RenderPipeline" = "UniversalPipeline" "IgnoreProjector" = "True"}
        Blend SrcAlpha OneMinusSrcAlpha

        Pass {
            Name "ForwardLit"
            Tags{"LightMode" = "UniversalForward"}

            HLSLPROGRAM
            #pragma target 5.0 // 5.0 required for tessellation

            #pragma multi_compile _ _MAIN_LIGHT_SHADOWS
            #pragma multi_compile _ _MAIN_LIGHT_SHADOWS_CASCADE
            #pragma multi_compile _ _ADDITIONAL_LIGHTS
            #pragma multi_compile_fragment _ _ADDITIONAL_LIGHT_SHADOWS
            #pragma multi_compile_fragment _ _SHADOWS_SOFT
            #pragma multi_compile_fog
            #pragma multi_compile_instancing

            // Material keywords
            #pragma shader_feature_local _PARTITIONING_INTEGER _PARTITIONING_FRAC_EVEN _PARTITIONING_FRAC_ODD _PARTITIONING_POW2
            #pragma shader_feature _SCALABLETESSELATION_ON   

            #pragma vertex Vertex
            #pragma hull Hull
            #pragma domain Domain
            #pragma fragment Fragment

            #include "TessellationFactors.hlsl"
            ENDHLSL
        }
    }

        CustomEditor "Needle.MarkdownShaderGUI"
}
