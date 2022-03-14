using System.Collections;
using System.Collections.Generic;
using UnityEngine;

[RequireComponent(typeof(Light))]
public class LightChanger : MonoBehaviour {
    public float daySpeed = 1;
    public Gradient LightGradient;
    public Gradient AmbientGradient;
    public Material skyMaterial;
    new private Light light;
    private float initialBrightness;
	// Use this for initialization
	void Start () {
        light = gameObject.GetComponent<Light>();
        initialBrightness = light.intensity;
    }
	
	// Update is called once per frame
	void Update () {
        transform.rotation *= Quaternion.AngleAxis(daySpeed * Time.deltaTime, new Vector3(1, 0, 0));
        //if(transform.rotation.eulerAngles.x > 355.0 ) {
        //   
        //}
        if(Vector3.Dot(-transform.forward, Vector3.down) > 0.5f) {
            transform.rotation *= Quaternion.AngleAxis(130, new Vector3(1, 0, 0));
        }
        float gradPos = Mathf.Repeat((transform.rotation.eulerAngles.x + 90) / 180, 1f);
        Color color = LightGradient.Evaluate(gradPos);
        //Debug.Log(gradPos);
        light.color = new Color(color.r, color.g, color.b);
        light.intensity = color.a * initialBrightness;
        Color ambientColor = AmbientGradient.Evaluate(gradPos);
        skyMaterial.SetColor("_AmbientLight", new Color(ambientColor.r, ambientColor.g, ambientColor.b) * color.a * initialBrightness * 0.3f);
        //skyMaterial.SetFloat("_CloudThickness", Mathf.Clamp(((Mathf.Sin(Time.time / 2f) / 5f) + 0.5f), 0f, 0.3f));
        //Debug.Log(skyMaterial.GetFloat("_CloudThickness"));
    }
}
