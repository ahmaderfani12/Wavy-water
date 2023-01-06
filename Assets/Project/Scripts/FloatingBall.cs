using System;
using System.Collections;
using System.Collections.Generic;
using UnityEngine;


public class FloatingBall : MonoBehaviour
{
    [SerializeField] private float _submergence;

    [SerializeField, Range(0,10)] float _buoyancy = 1f;

    [SerializeField] private WaveManager _waveManager;

    [SerializeField] private Material _waterMat;

    private Rigidbody _rb;
    private float h = 0;

    private void Awake()
    {
        _rb = this.GetComponent<Rigidbody>();
    }
    private void Update()
    {
        float bottomPos = (transform.position.y - transform.localScale.x / 2);

        float surfaceDis = h - bottomPos;

        _submergence = (transform.localScale.x - surfaceDis) / transform.localScale.x;

        _submergence =1 - Mathf.Clamp(_submergence, 0, 1);

        h = _waveManager.GetWaveHeight(Vector3.zero);

        UpdateWaterMat();
    }

    private void UpdateWaterMat()
    {
        _waterMat.SetVector("_Sphere_Position", this.transform.position);
        _waterMat.SetFloat("_Sphere_Mask_Radius", transform.localScale.x/2);
       //_waterMat.SetFloat("_Submergence", _submergence);
        _waterMat.SetFloat("_Sphere_Velocity", _rb.velocity.y);
    }

    private void FixedUpdate()
    {
        _rb.AddForce(new Vector3(0f, Mathf.Abs(Physics.gravity.y) * _submergence * _buoyancy, 0), ForceMode.Acceleration);
    }
}
