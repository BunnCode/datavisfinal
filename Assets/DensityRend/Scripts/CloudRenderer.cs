#if False
using System;
using System.Collections;
using System.Collections.Generic;
using UnityEngine;
using Valve.VR;


[RequireComponent(typeof(Camera))]
public class CloudRenderer : MonoBehaviour {
    public CameraClouds cameraClouds;
    public RenderTexture target;
    new Camera camera;
    void Start() {
        camera = gameObject.GetComponent<Camera>();
        if (SteamVR.instance != null)
        {
            target = new RenderTexture((int)(SteamVR.instance.sceneWidth / 5f), (int)(SteamVR.instance.sceneHeight / 5f), 24, RenderTextureFormat.ARGB2101010);
        }
        else
        {
            Debug.LogWarning("SteamVR instance null!");
            target = new RenderTexture(camera.pixelWidth, camera.pixelHeight, 24);
        }

        camera.targetTexture = target;
    }

    private void OnRenderImage(RenderTexture source, RenderTexture destination) {
        Graphics.Blit(source, destination);
    }
}
#endif