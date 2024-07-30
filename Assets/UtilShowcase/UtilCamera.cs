using System.Collections;
using System.Collections.Generic;
using System.IO.Compression;
using UnityEngine;
using UnityEngine.Android;

[RequireComponent(typeof(Camera))]
[ExecuteInEditMode]
public class UtilCamera : SceneViewFilter
{
    public float mouseSensitivty = 300f;
    public float moveSpeed = 20f;
    float xRotation = 0f;
    float yRotation = 0f; 
    void Start() {
        Cursor.lockState = CursorLockMode.Locked;
    }
    void Update() {
        float x = 0f, y = 0f, z = 0f;
        float mouseX = Input.GetAxis("Mouse X") * mouseSensitivty * Time.deltaTime;
        float mouseY = Input.GetAxis("Mouse Y") * mouseSensitivty * Time.deltaTime;
        xRotation -= mouseY;
        yRotation -= mouseX;
        xRotation = Mathf.Clamp(xRotation, -90f, 90f);  
    
        _planeInt = _showPlane ? 1 : 0;
        _replicate.x = _replicateX ? 1.0f : 0.0f;
        _replicate.y = _replicateY ? 1.0f : 0.0f;
        _replicate.z = _replicateZ ? 1.0f : 0.0f;
        _smooth = _smoothTransition ? 1 : 0;
        _rotateInt = _rotate ? 1 : 0;
        if (_bindLightToCamera) {
            _lightPos = _camera.transform.position;
        }
        
        // Camera Controls
        if (Input.GetKey(KeyCode.Space)) {
            y = 0.7f;
        }
        if (Input.GetKey(KeyCode.LeftShift)) {
            y = -0.7f;
        }
        if (Input.GetKey(KeyCode.W)) {
            z = 0.7f;
        }
        if (Input.GetKey(KeyCode.S)) {
            z = -0.7f;
        }
        if (Input.GetKey(KeyCode.A)) {
            x = -0.7f;
        }
        if (Input.GetKey(KeyCode.D)) {
            x = 0.7f;
        }

        Vector3 dir; 
        dir = transform.right * x + transform.up * y + transform.forward * z;
        transform.position += dir * Time.deltaTime*moveSpeed;
        transform.localRotation = Quaternion.Euler(xRotation, -yRotation, 0f);

    }
    
    
    [SerializeField]
    private Shader _shader;

    public Material _raymarchMaterial
    {
        get
        {
            if (!_raymarchMat && _shader)
            {
                _raymarchMat = new Material(_shader);
                _raymarchMat.hideFlags = HideFlags.HideAndDontSave;
            }
            return _raymarchMat;
        }
    }

    private Material _raymarchMat;
    
    public Camera _camera
    {
        get
        {
            if (!_cam)
            {
                _cam = GetComponent<Camera>();   
            }
            return _cam;

        }

    }
    public bool _lockCameraBool;
    int _lockCam;
    int _change;
    private Camera _cam;
    [Header("RayMarching")]
    [Range(1, 300)]
    public float _maxDistance;
    [Range(1, 1000)]
    public float _maxSteps;
    [Range(0.1f, 0.001f)]
    public float _surfDist;
    public Vector3 _lightPos;
    public bool _bindLightToCamera;

    [Range(0,1)]
    public float _colorIntensity;

    [Header("AmbientOcclusion")]
    [Range(0.01f, 10.0f)]
    public float _AOStepsize;
    [Range(0,1)]
    public float _AOIntensity;
    [Range(1,50)]
    public int _AOIterations;

    [Header("Mirroring")]
   
    Vector3 _replicate;
    public bool _replicateX;
    public bool _replicateY; 
    public bool _replicateZ; 

    [Range(0, 1)]
    int _replicateInt;
    public float _offset;

    [Header("Glow")]
    [Range(0f, 2f)]
    public float _glowIntensity;
    public Color _glowColor;

    [Header("Smoothness")]
    public bool _smoothTransition;
    int _smooth;
    [Range(0, 1)]
    public float _smoothness;
    
    [Header("Objects")]
    public Vector4 _box1;
    public Color _box1Color;
    public Color _sphere1Color;

    public Vector4 _box2;
    public Color _box2Color;
    public Color _sphere2Color;

    public Vector4 _box3;
    public Color _box3Color;
    public Color _torusColor;
    
    public Vector4 _torus;
    
    [Header("Plane")]
    public bool _showPlane = true;
    int _planeInt;
    public Color _planeColor = Color.white; 
    [Header("Rotate")]
    public bool _rotate;
    int _rotateInt; 

    void OnRenderImage(RenderTexture source, RenderTexture destination)
    {
        if(!_raymarchMaterial)
        {
            Graphics.Blit(source, destination);
            return;
        }

        _raymarchMaterial.SetMatrix("_CamFrustum", CamFrustum(_camera));
        _raymarchMaterial.SetMatrix("_CamToWorld", _camera.cameraToWorldMatrix);
        
        _raymarchMaterial.SetVector("_lightPos", _lightPos);
    
        _raymarchMaterial.SetFloat("_maxDistance", _maxDistance);
        _raymarchMaterial.SetFloat("_maxSteps", _maxSteps);
        _raymarchMaterial.SetFloat("_surfDist", _surfDist);
        
        _raymarchMaterial.SetFloat("_AOIntensity", _AOIntensity);
        _raymarchMaterial.SetFloat("_AOStepsize", _AOStepsize);
        _raymarchMaterial.SetInt("_AOIterations", _AOIterations);
        
        _raymarchMaterial.SetFloat("_colorIntensity", _colorIntensity);
        _raymarchMaterial.SetFloat("_glowIntensity", _glowIntensity);
        _raymarchMaterial.SetColor("_glowColor", _glowColor);
        
        _raymarchMaterial.SetVector("_replicate", _replicate);
        _raymarchMaterial.SetFloat("_offset", _offset);

        _raymarchMaterial.SetInt("_smooth", _smooth);
        _raymarchMaterial.SetFloat("_smoothness", _smoothness);
       
        _raymarchMaterial.SetVector("_planeColor", _planeColor);

        _raymarchMaterial.SetVector("_box1", _box1);
        _raymarchMaterial.SetVector("_box1Color", _box1Color);

        _raymarchMaterial.SetVector("_box2", _box2);
        _raymarchMaterial.SetVector("_box2Color", _box2Color);

        _raymarchMaterial.SetVector("_box3", _box3);
        _raymarchMaterial.SetVector("_box3Color", _box3Color);

        _raymarchMaterial.SetVector("_sphere1Color", _sphere1Color);
        _raymarchMaterial.SetVector("_sphere2Color", _sphere2Color);

        
        _raymarchMaterial.SetVector("_torus", _torus);
        _raymarchMaterial.SetVector("_torusColor", _torusColor); 

        _raymarchMaterial.SetInt("_rotate", _rotateInt); 


        RenderTexture.active = destination;
        _raymarchMaterial.SetTexture("_MainTex", source);
        GL.PushMatrix();
        GL.LoadOrtho();
        _raymarchMaterial.SetPass(0);
        GL.Begin(GL.QUADS);
        
        //Bottom Left
        GL.MultiTexCoord2(0, 0.0f, 0.0f);
        GL.Vertex3(0.0f, 0.0f, 3.0f);
        //Bottom Right
        GL.MultiTexCoord2(0, 1.0f, 0.0f);
        GL.Vertex3(1.0f, 0.0f, 2.0f);
        //Top Right
        GL.MultiTexCoord2(0, 1.0f, 1.0f);
        GL.Vertex3(1.0f, 1.0f, 1.0f);
        //Top Left
        GL.MultiTexCoord2(0, 0.0f, 1.0f);
        GL.Vertex3(0.0f, 1.0f, 0.0f);

        GL.End();
        GL.PopMatrix();
    }
    private Matrix4x4 CamFrustum(Camera cam)
    {
        Matrix4x4 frustum = Matrix4x4.identity;
        float fov = Mathf.Tan((cam.fieldOfView * 0.5f) * Mathf.Deg2Rad);

        Vector3 goUp = Vector3.up * fov;
        Vector3 goRight = Vector3.right * fov * cam.aspect;

        //calculating all corners of frustum based on aspectratio and fov
        Vector3 TL = (-Vector3.forward - goRight + goUp);
        Vector3 TR = (-Vector3.forward + goRight + goUp);
        Vector3 BR = (-Vector3.forward + goRight - goUp);
        Vector3 BL = (-Vector3.forward - goRight - goUp);
        
        frustum.SetRow(0, TL);
        frustum.SetRow(1, TR);
        frustum.SetRow(2, BR);
        frustum.SetRow(3, BL);

        return frustum;
    }
}
