using System;
using System.Collections;
using System.Collections.Generic;
using System.IO;
#if UNITY_EDITOR
using UnityEditor;
using UnityEditor.VersionControl;
#endif
using UnityEngine;
using UnityEngine.Rendering;
using UnityEngine.XR;

[RequireComponent(typeof(Camera))]
public class CameraDensityRend : MonoBehaviour {
    public string dataDir;
    public Renderer RendVolume;
    public Transform RendScaler;

    public ComputeShader NoiseShader;
    public ComputeShader PowShader;
    public Texture powTex;
    public Material blitMat;
    public Material densityMat;
    //public Transform rendTfm;
    public Texture blitTex;
    public Light Sun;
    public float eyeOffsetEnabled = 0;
    new private Camera camera;
    private Matrix4x4 planeMatrix;
    //public RenderTexture lowResTex;
    CommandBuffer densityBuffer;
    // Use this for initialization
    Vector4[] screenPoints;

    //Conversion between physical and logical indexes
    int to1DIndex(int x, int y, int z, int xMax, int yMax)
    {
        return (z * xMax * yMax) + (y * xMax) + x;
    }
    
    //Conversion between logical and physical indexes
    Vector3 to3DIndex(int idx, int xMax, int yMax)
    {
        int z = idx / (xMax * yMax);
        idx -= (z * xMax * yMax);
        int y = idx / xMax;
        int x = idx % xMax;
        return new Vector3(x, y, z);
    }

    private void Start() {
        int kernelHandle = NoiseShader.FindKernel("CSMain");

        //Generate fractional pow table
        RenderTexture fracPowTex = new RenderTexture(512, 512, 0, RenderTextureFormat.R8);
        fracPowTex.enableRandomWrite = true;
        fracPowTex.filterMode = FilterMode.Point;
        fracPowTex.wrapMode = TextureWrapMode.Repeat;
        fracPowTex.Create();
        PowShader.SetTexture(kernelHandle, "Result", fracPowTex);
        PowShader.SetVector("_Size", new Vector2(fracPowTex.width, fracPowTex.height));
        PowShader.Dispatch(kernelHandle, fracPowTex.width / 8, fracPowTex.height / 8, 1);
        Shader.SetGlobalTexture("_MapFracPow", fracPowTex);

        powTex = fracPowTex;
        if (camera.stereoTargetEye == StereoTargetEyeMask.Both) {
            screenPoints = new Vector4[] {
                new Vector4(-2f, 2f, 1f, 1f), //top left
            new Vector4(2f, 2f, 1f, 1f), //top right
            new Vector4(-2f, -2f, 1f, 1f), //bottom left
            new Vector4(2f, -2f, 1f, 1f) //bottom right
        };
        } else {
            screenPoints = new Vector4[] {

            new Vector4(-2f, 2f, 1f, 1f), //top left
            new Vector4(2f, 2f, 1f, 1f), //top right
            new Vector4(-2f, -2f, 1f, 1f), //bottom left
            new Vector4(2f, -2f, 1f, 1f) //bottom right
        };
        }

        //Load the raw data
#if UNITY_EDITOR
        //Editor only
        var dataObj = Resources.Load("rawdata");
        dataDir = AssetDatabase.GetAssetPath(dataObj);
#endif
        //Cached loading for standalone
        BinaryReader rdr = new BinaryReader(File.OpenRead(dataDir));

        //Read off dimensions on file
        int resX = rdr.ReadInt32();
        int resY = rdr.ReadInt32();
        int resZ = rdr.ReadInt32();

        //Get aspect ratio from file
        Vector3 aspectRatio = new Vector3(rdr.ReadSingle(), rdr.ReadSingle(), rdr.ReadSingle());
        densityMat.SetVector("_Scale", aspectRatio);

        //Allocate resources to create density tex
        Texture3D densityTex = new Texture3D(resX, resY, resZ, TextureFormat.RFloat, 0);
        int totalSize = resX * resY * resZ;
        float[] floats = new float[totalSize];
        Color[] colors = new Color[totalSize];

        //Read in the data from the file
        for (int i = 0; i < totalSize; i++) {
            float dataPoint = rdr.ReadSingle();
            floats[i] = dataPoint;
            
            int x = i % resX;
            int y = (i / resX) % resY;
            int z = i / (resX * resY);
            if (x == 0 || y == 0 || z == 0 ||
                x == resX - 1 || y == resY - 1 || z == resZ - 1) {
                //Prevent clamping issues
                colors[i] = new Color(0, 0, 0, 1);
            }
            else {
                colors[i] = new Color(dataPoint, 0, 0, 1);
            }
        }
        
        //Pack into texture
        densityTex.SetPixels(colors);

        //Set texture modes
        densityTex.wrapMode = TextureWrapMode.Clamp;
        densityTex.filterMode = FilterMode.Bilinear;

        //Bake texture
        densityTex.Apply();

#if UNITY_EDITOR
        //In the editor only, save to disk
        AssetDatabase.CreateAsset(densityTex, "Assets/DensityTex.asset");
        AssetDatabase.SaveAssets();
#endif

        //Bump to GPU
        Shader.SetGlobalTexture("_DensityTexture", densityTex);
        densityMat.SetTexture("_DensityTexture", densityTex);
    }


    void Awake() {
        camera = gameObject.GetComponent<Camera>();
        densityMat = Resources.Load<Material>("DensityMat");
        blitMat = new Material(Shader.Find("Custom/InverseDepthBlit"));
        //blitMat = new Material(Shader.Find("Custom/SteamVR_SphericalProjection"));
        blitTex = new RenderTexture(Screen.width, Screen.height, 24);
        camera.depthTextureMode = DepthTextureMode.Depth;
    }

    private void deviceLoaded(string str) {
        var inputDevices = new List<UnityEngine.XR.InputDevice>();
        UnityEngine.XR.InputDevices.GetDevices(inputDevices);
        bool test = false;
    }

    private void OnEnable() {
        densityBuffer = new CommandBuffer();
        densityBuffer.name = "Density Buffer";

        //Build the commandbuffer
        int targetID = Shader.PropertyToID("Density Buffer");
        if (camera.stereoTargetEye == StereoTargetEyeMask.Both) {
            densityBuffer.GetTemporaryRT(targetID, XRSettings.eyeTextureWidth, XRSettings.eyeTextureHeight, 24, FilterMode.Trilinear, RenderTextureFormat.ARGB32); } else {
            densityBuffer.GetTemporaryRT(targetID, (int)(Screen.width), (int)(Screen.height), 24, FilterMode.Trilinear, RenderTextureFormat.ARGB32);
        }
        densityBuffer.SetRenderTarget(targetID);
        densityBuffer.ClearRenderTarget(true, true, Color.clear);
      
        densityBuffer.Blit(BuiltinRenderTextureType.CurrentActive, BuiltinRenderTextureType.CurrentActive, densityMat);
        densityBuffer.SetRenderTarget(BuiltinRenderTextureType.None);
       
        densityBuffer.Blit(targetID, BuiltinRenderTextureType.CameraTarget, blitMat);
        densityBuffer.Blit(targetID, blitTex);
        densityBuffer.ReleaseTemporaryRT(targetID);

        //Bump commandbuffer to GPU
        camera.AddCommandBuffer(CameraEvent.BeforeForwardAlpha, densityBuffer);
        
        bool test = false;
        XRDevice.deviceLoaded += deviceLoaded;
        RendVolume.GetComponent<Renderer>().enabled = false;
    }

    private void OnDisable() {
        if (densityBuffer != null)
            camera.RemoveCommandBuffer(CameraEvent.BeforeForwardAlpha, densityBuffer);
    }


    private void OnPreRender()
    {
        //Bump updated info to GPU
        densityMat.SetVector("_Center", RendScaler.position);
        Bounds b = RendVolume.bounds;
        densityMat.SetVector("_AABBMin", b.min);
        densityMat.SetVector("_AABBMax", b.max);

        Shader.SetGlobalVector("_CameraPosition", camera.transform.position);
        Shader.SetGlobalVector("_CameraRight", camera.transform.right);
        Shader.SetGlobalVector("_CameraUp", camera.transform.up);
        Shader.SetGlobalVector("_CameraForward", camera.transform.forward);
        Shader.SetGlobalVector("_SunColor", Sun.color * Sun.intensity);
        Shader.SetGlobalVector("_SunPos", -Sun.transform.forward * 50000f);
        if (camera.stereoTargetEye == StereoTargetEyeMask.Both) {
            //VR rendering
            Shader.SetGlobalFloat("_AspectRatio", (float)XRSettings.eyeTextureWidth / (float)XRSettings.eyeTextureHeight);/*((float)SteamVR.instance.sceneWidth) / (float)SteamVR.instance.sceneHeight)*/
            Shader.SetGlobalFloat("_FieldOfView", camera.fieldOfView);

            Shader.SetGlobalMatrix("_LeftEyeVectorMatrix", vectorMatrix(camera, Camera.StereoscopicEye.Left, Color.red));
            Shader.SetGlobalMatrix("_RightEyeVectorMatrix", vectorMatrix(camera, Camera.StereoscopicEye.Right, Color.blue));
        } else {
            //non VR rendering
            Shader.SetGlobalFloat("_AspectRatio", (float)camera.pixelWidth / (float)camera.pixelHeight);
            Shader.SetGlobalFloat("_FieldOfView", Mathf.Tan(camera.fieldOfView * Mathf.Deg2Rad * 0.5f) * 2f);

            Shader.SetGlobalMatrix("_RightEyeVectorMatrix", vectorMatrix(camera, Camera.StereoscopicEye.Left, Color.red));
        }

    }

    //Used to generate information required for volume rendering by packing multiple vectors into a matrix for later use
    private Matrix4x4 vectorMatrix(Camera cam, Camera.StereoscopicEye eye, Color color) {
        Matrix4x4 frustumCorners = Matrix4x4.identity;
        //Offset of each eye
        Vector4 eyeOffset = Vector4.zero;
        //Matrix representing the transformation by that offset
        Matrix4x4 eyeOffsetMatrix;
        //Todo: Reverse engineer exactly what's being packed into this matrix (?)
        Matrix4x4 translationMatrix;
        //VR matrix
        if (camera.stereoTargetEye == StereoTargetEyeMask.Both) {
            
            //Get the per-eye offset
            if (eye == Camera.StereoscopicEye.Left) {
                eyeOffset = new Vector4(-camera.stereoSeparation, 0, 0); 
            } else {
                eyeOffset = new Vector4(camera.stereoSeparation, 0, 0); 
            }
            //Resolve the TRS from that offset
            eyeOffsetMatrix = Matrix4x4.TRS(eyeOffset, Quaternion.identity, Vector3.one);
            //Calculate translation matrix to convert from screenspace to worldspace
            translationMatrix = 
                (cam.cameraToWorldMatrix * eyeOffsetMatrix) * 
                Matrix4x4.Inverse(camera.GetStereoProjectionMatrix(eye)
                );

        }
        //Non VR Matrix info
        else {
            eyeOffset = Vector3.zero;
            translationMatrix = Matrix4x4.Inverse(camera.projectionMatrix * cam.worldToCameraMatrix);
        }
       
        for (int i = 0; i < screenPoints.Length; i++) {
            //todo: This is a hack but it works for now
            Vector4 camForward4 = translationMatrix * (screenPoints[i] + (eyeOffset * 2));
            Vector3 camForward = new Vector3(camForward4.x, camForward4.y, camForward4.z) / camForward4.w;
            Vector3 normalized = Vector3.Normalize(camForward);
            frustumCorners.SetRow(i, normalized);
            Debug.DrawLine(camera.transform.position + (camera.transform.rotation * eyeOffset), camForward, color, 0.1f);
        }
        return frustumCorners;
    }
}
