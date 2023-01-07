using System;
using System.Collections;
using System.Collections.Generic;
using UnityEngine;


public class FloatingBall : MonoBehaviour
{
    [SerializeField, Range(0.9f,2)] float _buoyancy = 1f;

    [SerializeField] private WaveManager _waveManager;

    private float _submergence;
    private Rigidbody _rb;
    private float waveHeight = 0;

    private void Awake()
    {
        _rb = this.GetComponent<Rigidbody>();
    }
    private void Update()
    {
        float bottomPos = (transform.position.y - transform.localScale.x / 2);

        float surfaceDis = waveHeight - bottomPos;

        _submergence = (transform.localScale.x - surfaceDis) / transform.localScale.x;

        _submergence =1 - Mathf.Clamp(_submergence, 0, 1);

        waveHeight = _waveManager.GetWaveHeight(Vector3.zero);
    }

    private void FixedUpdate()
    {
        _rb.AddForce(new Vector3(0f, Mathf.Abs(Physics.gravity.y) * _submergence * _buoyancy, 0), ForceMode.Acceleration);
    }
}
