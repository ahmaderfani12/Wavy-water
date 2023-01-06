
struct WaveData
{
    float3 pos;
    float heighDist;
    float frec;
};

WaveData GerstnerWave_float(float3 pos, float3 prop, float2 dir, float time)
{
    
    float3 newPos = pos;
    float sharpness = prop.x;
    float waveLength = prop.y * 10;
    float speed = prop.z;
    dir = normalize(dir);
    
    float f = 2 * 3.1415 / waveLength;
    float s = sqrt(9.8 / f) * speed;
    float k = f * (dot(dir, pos.xz) + time * s);
    float a = sharpness / f;
    
    newPos.y = a * sin(k);
    newPos.x = dir.x * (a * cos(k));
    newPos.z = dir.y * (a * cos(k));
    
    float maxHeight = a;
    
    WaveData waveData;
    waveData.pos = newPos;
    waveData.heighDist = 1.0 - (maxHeight - newPos.y);
    waveData.frec = f;
    
    return waveData;
}

void WavePos_float(float3 _pos, float3 _w1Porp, float2 _dir1, float3 _w2Porp, float2 _dir2, float3 _w3Porp, float2 _dir3, float _time, float _mask, out float3 _newPos, out float _maxHeight)
{

    float3 newPos = _pos;
    WaveData w1 = GerstnerWave_float(_pos, _w1Porp, _dir1, _time);
    WaveData w2 = GerstnerWave_float(_pos, _w2Porp, _dir2, _time);
    WaveData w3 = GerstnerWave_float(_pos, _w3Porp, _dir3, _time);
    
    newPos += w1.pos;
    newPos += w2.pos;
    newPos += w3.pos;
    
    _newPos = newPos;
    //_newPos = lerp(_pos, newPos, _mask);
    _maxHeight = (w1.heighDist * w1.frec) + (w2.heighDist * w2.frec) + (w3.heighDist * w3.frec);

}

