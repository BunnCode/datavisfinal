using System.Collections;
using System.Collections.Generic;
using UnityEngine;
using UnityEngine.Rendering;
#if False
[RequireComponent(typeof(Camera))]
public class CameraClouds : MonoBehaviour {
    public ComputeShader NoiseShader;
    public ComputeShader PowShader;
    public Texture powTex;
    public Material blitMat;
    public Material cloudMat;
    public MeshFilter meshFilter;
    public Transform cloudTransform;
    public Texture blitTex;
    public Light Sun;
    public float eyeOffsetEnabled = 0;
    new private Camera camera;
    private Matrix4x4 planeMatrix;
    //public RenderTexture lowResTex;
    CommandBuffer cloudBuffer;
    // Use this for initialization
    Vector4[] screenPoints;

    private void Start() {
        int kernelHandle = NoiseShader.FindKernel("CSMain");

        //Generate noise
        RenderTexture noiseTex = new RenderTexture(1024, 1024, 0, RenderTextureFormat.R8);
        noiseTex.dimension = TextureDimension.Tex3D;
        noiseTex.volumeDepth = 1000;
        noiseTex.enableRandomWrite = true;
        noiseTex.wrapMode = TextureWrapMode.Repeat;
        noiseTex.filterMode = FilterMode.Point;
        //noiseTex.filterMode = FilterMode.Bilinear;
        noiseTex.useMipMap = false;
        //tex.format = RenderTextureFormat.R8;
        noiseTex.Create();
        RenderTexture.active = noiseTex;
        NoiseShader.SetTexture(kernelHandle, "Result", noiseTex);
        NoiseShader.Dispatch(kernelHandle, noiseTex.width / 8, noiseTex.height / 8, noiseTex.volumeDepth / 8);
        Shader.SetGlobalTexture("_MapNoise", noiseTex);
        //noiseTex.enableRandomWrite = false;

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
        //fracPowTex.enableRandomWrite = false;
        powTex = fracPowTex;
        if (SteamVR.instance != null && camera.stereoTargetEye == StereoTargetEyeMask.Both) {
            screenPoints = new Vector4[] {

            new Vector4(-2f, 2f, 0f, 1f), //top left
            new Vector4(2f, 2f, 0f, 1f), //top right
            new Vector4(-2f, -2f, 0f, 1f), //bottom left
            new Vector4(2f, -2f, 0f, 1f) //bottom right
        };
        } else {
            screenPoints = new Vector4[] {

            new Vector4(-2f, 2f, 1f, 1f), //top left
            new Vector4(2f, 2f, 1f, 1f), //top right
            new Vector4(-2f, -2f, 1f, 1f), //bottom left
            new Vector4(2f, -2f, 1f, 1f) //bottom right
        };
        }
    }


    void Awake() {
        camera = gameObject.GetComponent<Camera>();
        meshFilter = gameObject.GetComponent<MeshFilter>();
        cloudMat = Resources.Load<Material>("CloudMat");
        blitMat = new Material(Shader.Find("Custom/InverseDepthBlit"));
        //blitMat = new Material(Shader.Find("Custom/SteamVR_SphericalProjection"));
        blitTex = new RenderTexture(Screen.width, Screen.height, 24);
        camera.depthTextureMode = DepthTextureMode.Depth;
    }

    private Matrix4x4 HMDMatrix4x4ToMatrix4x4(Valve.VR.HmdMatrix44_t input) {
        var m = Matrix4x4.identity;
        m[0, 0] = input.m0;
        m[0, 1] = input.m1;
        m[0, 2] = input.m2;
        m[0, 3] = input.m3;
        m[1, 0] = input.m4;
        m[1, 1] = input.m5;
        m[1, 2] = input.m6;
        m[1, 3] = input.m7;
        m[2, 0] = input.m8;
        m[2, 1] = input.m9;
        m[2, 2] = input.m10;
        m[2, 3] = input.m11;
        m[3, 0] = input.m12;
        m[3, 1] = input.m13;
        m[3, 2] = input.m14;
        m[3, 3] = input.m15;
        return m;
    }

    private void OnEnable() {
        cloudBuffer = new CommandBuffer();
        cloudBuffer.name = "CloudBuffer";

        //cloudBuffer.SetRenderTarget(lowResTex);
        //lowResTex = new RenderTexture(Screen.width / 5, Screen.height / 5, 24);
        int targetID = Shader.PropertyToID("Cloud Buffer");
        if (SteamVR.instance != null && camera.stereoTargetEye == StereoTargetEyeMask.Both) {
            cloudBuffer.GetTemporaryRT(targetID, (int)(SteamVR.instance.sceneWidth / 2f), (int)(SteamVR.instance.sceneHeight / 2f), 24, FilterMode.Trilinear, RenderTextureFormat.ARGB32);
        } else {
            cloudBuffer.GetTemporaryRT(targetID, (int)(Screen.width), (int)(Screen.height), 24, FilterMode.Trilinear, RenderTextureFormat.ARGB32);
        }
        //cloudBuffer.SetGlobalTexture("_CurrentDepth", BuiltinRenderTextureType.Depth);
        cloudBuffer.SetRenderTarget(targetID);
        cloudBuffer.ClearRenderTarget(true, true, Color.clear);
        // cloudBuffer.DrawMesh(meshFilter.mesh, planeMatrix, densityMat);
        //cloudBuffer.SetProjectionMatrix(HMDMatrix4x4ToMatrix4x4(SteamVR.instance.hmd.GetProjectionMatrix(SteamVR.instance.eyes., _vrEye.nearClipPlane, _vrEye.farClipPlane, Valve.VR.EGraphicsAPIConvention.API_DirectX));
        cloudBuffer.Blit(BuiltinRenderTextureType.CurrentActive, BuiltinRenderTextureType.CurrentActive, cloudMat);
        cloudBuffer.SetRenderTarget(BuiltinRenderTextureType.None);
        //cloudBuffer.Blit(BuiltinRenderTextureType.CameraTarget, BuiltinRenderTextureType.CameraTarget);
        cloudBuffer.Blit(targetID, BuiltinRenderTextureType.CameraTarget, blitMat);
        cloudBuffer.Blit(targetID, blitTex);
        cloudBuffer.ReleaseTemporaryRT(targetID);
        //planeMatrix = rendTfm.localToWorldMatrix;


        //cloudBuffer.Blit(BuiltinRenderTextureType.CurrentActive, BuiltinRenderTextureType.CurrentActive, blitMat);
        camera.AddCommandBuffer(CameraEvent.BeforeForwardAlpha, cloudBuffer);
    }

    private void OnDisable() {
        if (cloudBuffer != null)
            camera.RemoveCommandBuffer(CameraEvent.BeforeForwardAlpha, cloudBuffer);
    }


    private void OnPreRender() {
        //cloudBuffer.Clear();
        //Pass camera info to shaders
        // Vector3 eyeOffset = transform.rotation * SteamVR.instance.eyes[0].pos;
        Shader.SetGlobalVector("_CameraPosition", camera.transform.position);
        Shader.SetGlobalVector("_CameraRight", camera.transform.right);
        Shader.SetGlobalVector("_CameraUp", camera.transform.up);
        Shader.SetGlobalVector("_CameraForward", camera.transform.forward);
        //Shader.SetGlobalVector("_EyeOffset", SteamVR.instance.eyes[0].pos);
        Shader.SetGlobalVector("_SunColor", Sun.color * Sun.intensity);
        Shader.SetGlobalVector("_SunPos", -Sun.transform.forward * 50000f);
        //Shader.SetGlobalVector("_SunDir", Sun.transform.forward);
        // Shader.SetGlobalFloat("_AspectRatio", (float)SteamVR.instance.sceneWidth / (float)SteamVR.instance.sceneHeight);
        if (SteamVR.instance != null && camera.stereoTargetEye == StereoTargetEyeMask.Both) {
            Shader.SetGlobalFloat("_AspectRatio", /*(float)camera.pixelWidth / (float)camera.pixelHeight*/((float)SteamVR.instance.sceneWidth) / (float)SteamVR.instance.sceneHeight);
            Shader.SetGlobalFloat("_FieldOfView", Mathf.Tan(SteamVR.instance.fieldOfView * Mathf.Deg2Rad * 0.5f) * 2f);
            Shader.SetGlobalFloat("_FieldOfView", Mathf.Tan((SteamVR.instance.fieldOfView / 2f)/*1.111111111f*/ * Mathf.Deg2Rad * 0.5f) * 2f);
            Shader.SetGlobalMatrix("_LeftEyeVectorMatrix", vectorMatrix(camera, Valve.VR.EVREye.Eye_Left, Color.red));
            Shader.SetGlobalMatrix("_RightEyeVectorMatrix", vectorMatrix(camera, Valve.VR.EVREye.Eye_Right, Color.blue));
            Shader.SetGlobalVector("_EyeOffset", camera.transform.rotation * SteamVR.instance.eyes[0].pos);
        } else {
            Shader.SetGlobalFloat("_AspectRatio", (float)camera.pixelWidth / (float)camera.pixelHeight);
            // Shader.SetGlobalFloat("_FieldOfView", Mathf.Tan(SteamVR.instance.fieldOfView * Mathf.Deg2Rad * 0.5f) * 2f);
            Shader.SetGlobalFloat("_FieldOfView", Mathf.Tan(camera.fieldOfView * Mathf.Deg2Rad * 0.5f) * 2f);
            Shader.SetGlobalMatrix("_RightEyeVectorMatrix", vectorMatrix(camera, Valve.VR.EVREye.Eye_Left, Color.red));
        }

    }

    private Matrix4x4 vectorMatrix(Camera cam, Valve.VR.EVREye eye, Color color) {
        Matrix4x4 frustumCorners = Matrix4x4.identity;
        Vector3 eyeOffset = Vector3.zero;
        Matrix4x4 eyeOffsetMatrix;
        Matrix4x4 translationMatrix;
        //VR matrix
        if (SteamVR.instance != null && camera.stereoTargetEye == StereoTargetEyeMask.Both) {
            if (eye == Valve.VR.EVREye.Eye_Left) {
                eyeOffset = SteamVR.instance.eyes[0].pos;
            } else {
                eyeOffset = SteamVR.instance.eyes[1].pos;
            }

            eyeOffsetMatrix = Matrix4x4.TRS(camera.transform.position, Quaternion.identity, Vector3.one);
            translationMatrix = Matrix4x4.Inverse(
               HMDMatrix4x4ToMatrix4x4(
                   SteamVR.instance.hmd.GetProjectionMatrix(
                       eye,
                       camera.nearClipPlane,
                       camera.farClipPlane
                       )) * cam.worldToCameraMatrix /* eyeOffsetMatrix*/);
        }
        //Hon VR Matrix info
        else {
            eyeOffset = Vector3.zero;

            //eyeOffsetMatrix = Matrix4x4.TRS(camera.transform.position, camera.transform.rotation, Vector3.one);
            translationMatrix = Matrix4x4.Inverse(camera.projectionMatrix * cam.worldToCameraMatrix);
        }
        // Matrix4x4 eyeOffsetMatrix = Matrix4x4.TRS((eyeOffset * eyeOffsetEnabled) + camera.transform.position, Quaternion.identity, Vector3.one);


        //Matrix4x4 translationMatrix = Matrix4x4.Inverse(cam.projectionMatrix * cam.worldToCameraMatrix);
        // Vector3[] frustumCornersVectors = new Vector3[4];
        for (int i = 0; i < screenPoints.Length; i++) {
            Vector4 camForward4 = translationMatrix * screenPoints[i];
            // Vector3 camForward = new Vector3(camForward4.x, camForward4.y, camForward4.z) / camForward4.w;
            //camForward.y appears to be haeving problem for some reason. As it gets "higher" (looking up, or in its direction) steps begin developing.
            Vector3 camForward = new Vector3(camForward4.x, camForward4.y, camForward4.z) / camForward4.w;
            //frustumCornersVectors[i] = camForward;
            frustumCorners.SetRow(i, Vector3.Normalize(camForward));
            Debug.DrawLine(camera.transform.position, camForward, color, 0.1f);
        }
        return frustumCorners;
    }


    //private void OnRenderImage(RenderTexture source, RenderTexture destination) {
    //Graphics.Blit(source, destination, densityMat);
    //}
}
#endif