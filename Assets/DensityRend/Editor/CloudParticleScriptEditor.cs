using System.Collections;
using System.Collections.Generic;
using UnityEngine;
using UnityEditor;

[CanEditMultipleObjects]
[CustomEditor(typeof(CloudparticleScript))]
public class CloudParticleScriptEditor : Editor{
    float lifetime = 1;
    public override void OnInspectorGUI() {
        lifetime = EditorGUILayout.FloatField("Lifetime of generation:", lifetime);
        if (GUILayout.Button("Generate Cloud")) {
            foreach(CloudparticleScript cloud in targets) {
                cloud.GenerateCloud(lifetime);
            }   
        }
    }
}
