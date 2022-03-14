using System.Collections;
using System.Collections.Generic;
using UnityEngine;

[ExecuteInEditMode]
public class CloudparticleScript : MonoBehaviour {
    public void GenerateCloud(float time) {
        ParticleSystem part = gameObject.GetComponent<ParticleSystem>();
        StartCoroutine(RunThenStop(part, time));
    }

    public IEnumerator RunThenStop(ParticleSystem part, float time) {
        float totalTime = 0;
        var main = part.main;
        main.simulationSpeed = 1;
        main.startLifetime = time + 0.001f;
        var emission = part.emission;
        emission.rateOverTimeMultiplier = time * 1000;
        main.duration = main.startLifetime.constant;
        part.Clear();
        part.Play();
        while (totalTime < time - 0.001) {
            totalTime += Time.deltaTime;
            yield return new WaitForSeconds(0.01f);
        }
       
        main.simulationSpeed = 0;
        part.Stop();
    }
}

