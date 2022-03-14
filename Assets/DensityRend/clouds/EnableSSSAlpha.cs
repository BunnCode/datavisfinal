using System.Collections;
using System.Collections.Generic;
using UnityEngine;

public class EnableSSSAlpha : MonoBehaviour {

	// Use this for initialization
	void Start () {
        
        
    }
	
	// Update is called once per frame
	void Update () {
        Material[] materials = gameObject.GetComponent<Renderer>().sharedMaterials;
        foreach (Material mat in materials) {
            if (mat) {
                mat.DisableKeyword("TRANSPARENT");
                //mat.DisableKeyword("OPAQUE");
                Debug.Log(mat.shaderKeywords);
            }
            mat.shaderKeywords = new string[] { "Opaque" };
        }
    }
}
