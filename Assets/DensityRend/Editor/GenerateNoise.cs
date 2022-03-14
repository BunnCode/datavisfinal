using System.Collections;
using System.Collections.Generic;
using UnityEditor;
using UnityEngine;

public class GenerateNoise : EditorWindow {
    [MenuItem("Window/Generate Noise")]
    public static void ShowWindow() {
        EditorWindow.GetWindow(typeof(GenerateNoise));
    }
    Vector2 MOD2;
    Vector3 MOD3;
    public ComputeShader shader;
    public RenderTexture tex;

    public Vector2 size = new Vector2(100, 100);
    public Texture2D TexOut;

    void OnGUI() {
        if (GUILayout.Button("Create Noise")) {
            Generate();
        }
    }

    void Generate() {
        shader = (ComputeShader)Resources.Load("GenerateNoise");
        int kernelHandle = shader.FindKernel("CSMain");
        tex = new RenderTexture(1024, 1024, 0, RenderTextureFormat.R8);
        RenderTexture.active = tex;
       
        
        AssetDatabase.StartAssetEditing();
        tex.dimension = UnityEngine.Rendering.TextureDimension.Tex3D;
        tex.volumeDepth = 1000;
        tex.enableRandomWrite = true;
        tex.wrapMode = TextureWrapMode.Repeat;
        tex.filterMode = FilterMode.Point;
        //tex.format = RenderTextureFormat.R8;
        tex.Create();
        shader.SetTexture(kernelHandle, "Result", tex);
        shader.Dispatch(kernelHandle, tex.width / 8, tex.height / 8, tex.volumeDepth / 8);
        Texture3D texSave = new Texture3D(tex.width, tex.width, tex.depth, TextureFormat.RFloat, false);
       // texSave = tex.;
        //texSave.Apply();
       // AssetDatabase.CreateAsset(tex, "Assets/SSS Clouds/Resources/Noise.asset");
        //tex = (Texture)(AssetDatabase.LoadAssetAtPath("Assets/SSS Clouds/Resources/Noise.asset", typeof(Texture)));

        //AssetDatabase.StopAssetEditing();
        //EditorUtility.SetDirty(tex);
        //AssetDatabase.SaveAssets();
        //AssetDatabase.SaveAssets();
        //DestroyImmediate(tex);
        //AssetDatabase.Refresh();
        //AssetDatabase.SaveAssets();
    }
}
