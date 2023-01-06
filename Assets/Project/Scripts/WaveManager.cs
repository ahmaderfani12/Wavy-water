using System.Collections;
using System.Collections.Generic;
using UnityEngine;

public class WaveManager : MonoBehaviour
{

    [SerializeField] Material _waterMat;

    [SerializeField] WaveProp _wave1;
    [SerializeField] WaveProp _wave2;
    [SerializeField] WaveProp _wave3;

    private static float _time
    {
        get
        {
        #if UNITY_EDITOR
                    return Application.isPlaying ? Time.time : Shader.GetGlobalVector("_Time").x;
        #else
                        return Time.time;
        #endif
        }
    }

    public float GetWaveHeight(Vector3 pos)
    {
        Vector3 newPos = SinWave(pos,
            new Vector3(_wave1.sharpness, _wave1.waveLenght, _wave1.speed), _wave1.direction,
            new Vector3(_wave2.sharpness, _wave2.waveLenght, _wave2.speed), _wave2.direction,
            new Vector3(_wave3.sharpness, _wave3.waveLenght, _wave3.speed), _wave3.direction, _time, 1);

        return newPos.y;
    }


    private void Update()
    {
        UpdateMaterial();
    }

    [ContextMenu("Update Material")]
    private void UpdateMaterial()
    {
        _waterMat.SetVector("_W1_Prop_Sharpness_WaveLength_Speed", new Vector3(_wave1.sharpness, _wave1.waveLenght, _wave1.speed));
        _waterMat.SetVector("_W1_Direction", _wave1.direction);

        _waterMat.SetVector("_W2_Prop_Sharpness_WaveLength_Speed", new Vector3(_wave2.sharpness, _wave2.waveLenght, _wave2.speed));
        _waterMat.SetVector("_W2_Direction", _wave2.direction);

        _waterMat.SetVector("_W3_Prop_Sharpness_WaveLength_Speed", new Vector3(_wave3.sharpness, _wave3.waveLenght, _wave3.speed));
        _waterMat.SetVector("_W3_Direction", _wave3.direction);
    }

    Vector3 SinWave(Vector3 _pos,
        Vector3 _w1Porp, Vector2 _dir1,
        Vector3 _w2Porp, Vector2 _dir2,
        Vector3 _w3Porp, Vector2 _dir3,
        float _time, float _mask)
    {

        Vector3 newPos = _pos;
        WaveData w1 = GerstnerWave_float(_pos, _w1Porp, _dir1, _time);
        WaveData w2 = GerstnerWave_float(_pos, _w2Porp, _dir2, _time);
        WaveData w3 = GerstnerWave_float(_pos, _w3Porp, _dir3, _time);

        newPos += w1.pos;
        newPos += w2.pos;
        newPos += w3.pos;


        return Vector2.Lerp(_pos, newPos, _mask);

    }

    WaveData GerstnerWave_float(Vector3 pos, Vector3 prop, Vector2 dir, float time)
    {

        Vector3 newPos = pos;
        float sharpness = prop.x;
        float waveLength = prop.y * 10;
        float speed = prop.z;
        dir = dir.normalized;

        float f = 2 * 3.1415f / waveLength;
        float s = Mathf.Sqrt(9.8f / f) * speed;
        float k = f * (Vector2.Dot(dir, new Vector2(pos.x,pos.z)) + time * s);
        float a = sharpness / f;

        newPos.y = a * Mathf.Sin(k);
        newPos.x = dir.x * (a * Mathf.Cos(k));
        newPos.z = dir.y * (a * Mathf.Cos(k));

        float maxHeight = a;

        WaveData waveData;
        waveData.pos = newPos;
        waveData.heighDist = 1.0f - (maxHeight - newPos.y);
        waveData.frec = f;

        return waveData;
    }

}

public struct WaveData
{
    public Vector3 pos;
    public float heighDist;
    public float frec;
};

[System.Serializable]
public struct WaveProp
{
    [Range(0,1)] public float sharpness;
    [Range(0, 1)]  public float waveLenght;
    [Range(0, 1)]  public float speed;
    public Vector2 direction;
};
