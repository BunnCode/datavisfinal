
/*using System.Collections;
using System.Collections.Generic;
using System.Linq;
using UnityEngine;

public class Movement : MonoBehaviour {
    public SteamVR_TrackedObject controllerRight;
    private SteamVR_Controller.Device controllerRightDevice;

    public SteamVR_TrackedObject controllerLeft;
    private SteamVR_Controller.Device controllerLeftDevice;

    public GameObject eyeParent;
    public GameObject headset;
    public Camera headCam;
    public Collider playerPhysBounds;
    private Quaternion targetRotation;
    public float moveDistance = 0.2f;
    public float moveTime = 0.2f;

    public Collider playerBounds;
    private float playerHeight;

    private bool moving = false;
    float totalTime = 0f;
    private float distanceMoved;
    private Vector3 moveStartPosition;
    private Vector3 touchpadPosition = Vector3.zero;
    private Vector3 lastHeadPos;
    private Quaternion lastBodyRot;
    // Use this for initialization
    void Start() {
        playerHeight = playerBounds.bounds.extents.y * 2;
        targetRotation = playerPhysBounds.transform.rotation;  
    }
    
    void OnEnable() {
        //playerPhysBounds.transform.position = headCam.transform.position;
        lastHeadPos = headCam.transform.localPosition;
        PositionalUpdate();
        playerPhysBounds.enabled = true;
        playerPhysBounds.transform.localPosition += new Vector3(0, playerPhysBounds.GetComponent<Collider>().bounds.extents.y, 0);
    }

    void Update() {
        try {
            controllerLeftDevice = SteamVR_Controller.Input((int)controllerLeft.index);
        } catch (System.Exception) { }


        // Smoothly rotates player upwards
        //transform.rotation = playerPhysBounds.transform.rotation;
        //var targetRotation = Quaternion.LookRotation(Vector3.up - playerPhysBounds.transform.position, Vector3.up);
        //playerPhysBounds.transform.rotation = Quaternion.Slerp(playerPhysBounds.transform.rotation, targetRotation, Time.deltaTime * 10f);
    }

    
    public void Teleport() {
        Quaternion oldRootRot = transform.rotation;
        Vector3 oldRootEuler = transform.rotation.eulerAngles;
        Vector3 oldRootPos = transform.position;
        Quaternion oldPhysRot = playerPhysBounds.transform.rotation;
        Vector3 oldPhysEuler = oldPhysRot.eulerAngles;
        Vector3 oldPhysPos = playerPhysBounds.transform.position;
        Vector3 oldPhysEulerLocal = playerPhysBounds.transform.localRotation.eulerAngles;

        Vector3 relDestPos = playerPhysBounds.transform.InverseTransformPoint(oldRootPos);
        targetRotation = transform.rotation * Quaternion.Euler(0, lastBodyRot.eulerAngles.y, 0);
        targetRotation = Quaternion.Euler(new Vector3(0, targetRotation.eulerAngles.y, 0));
        Transform oldParent = transform.parent;
        transform.SetParent(playerPhysBounds.transform);
        playerPhysBounds.transform.position = oldPhysPos;
        playerPhysBounds.transform.rotation = oldPhysRot;
        transform.rotation = Quaternion.Euler(0, transform.localRotation.eulerAngles.y, 0);
        playerPhysBounds.transform.rotation = oldPhysRot;

        Vector3 oldCameraPos = eyeParent.transform.position;
        playerPhysBounds.transform.localRotation = Quaternion.Euler(oldPhysEuler.x, lastBodyRot.eulerAngles.y, oldPhysEuler.z);
        eyeParent.transform.position = oldCameraPos;
        //playerPhysBounds.transform.localPosition = new Vector3(headCam.transform.position.x, playerPhysBounds.transform.localPosition.y, headCam.transform.position.z);
        lastHeadPos = headCam.transform.localPosition;
    }

    // Update is called once per frame
    void LateUpdate() {
        controllerRightDevice = SteamVR_Controller.Input((int)controllerRight.index);
        //HeadsetDevice = SteamVR_Controller.Input((int)HeadsetDevice.index);

        if (controllerRightDevice.GetPressDown(SteamVR_Controller.ButtonMask.Touchpad) && !moving) {
            touchpadPosition = new Vector3(controllerRightDevice.GetAxis(Valve.VR.EVRButtonId.k_EButton_SteamVR_Touchpad).x, 0, controllerRightDevice.GetAxis(Valve.VR.EVRButtonId.k_EButton_SteamVR_Touchpad).y);
            distanceMoved = 0f;
            moving = true;
            moveStartPosition = transform.position;
        }

        if (moving && totalTime < moveTime) {
            moveByDelta(moveStartPosition, new Vector3(touchpadPosition.x * moveDistance, 0, touchpadPosition.z * moveDistance) * transform.lossyScale.magnitude, moveTime);
        }

        if (totalTime >= moveTime) {
            moving = false;
            totalTime = 0f;
        }
        PositionalUpdate();
    }

    private void PositionalUpdate() {
      
        Vector3 diffPos = headCam.transform.localPosition - lastHeadPos;
        playerPhysBounds.transform.localPosition += new Vector3(diffPos.x, 0, diffPos.z);
        //playerPhysBounds.transform.localPosition += new Vector3(diffPos.x, 0, diffPos.z);
        //Vertical movement
        eyeParent.transform.localPosition = new Vector3(eyeParent.transform.localPosition.x, diffPos.y, eyeParent.transform.localPosition.z);
        
        //Camera movement /w physical control override
        Vector3 oldEuler = playerPhysBounds.transform.localRotation.eulerAngles;
        Transform oldParent = eyeParent.transform.parent;
        eyeParent.transform.SetParent(playerPhysBounds.transform);
        eyeParent.transform.localPosition = (-headCam.transform.localPosition);

        eyeParent.transform.localPosition = new Vector3(eyeParent.transform.localPosition.x, 
            playerPhysBounds.bounds.extents.y - (playerPhysBounds.bounds.extents.y * 2), 
            eyeParent.transform.localPosition.z);

        //Cache new position
        lastHeadPos = headCam.transform.localPosition;
        lastBodyRot = playerPhysBounds.transform.localRotation;
    }

    void FixedUpdate() {
        playerPhysBounds.transform.rotation = Quaternion.Slerp(playerPhysBounds.transform.rotation, targetRotation, Time.deltaTime * 3f);
        
        //Vector3 oldPos = playerPhysBounds.transform.localPosition;
        //transform.position = new Vector3(transform.position.x, playerPhysBounds.transform.position.y, transform.position.z);
        //playerPhysBounds.transform.localPosition = oldPos;

        //eyeParent.transform.position = playerPhysBounds.transform.position;
        //eyeParent.transform.position = playerPhysBounds.transform.TransformPoint(-headCam.transform.localPosition);
        //eyeParent.transform.rotation = playerPhysBounds.transform.rotation;
       
        
    }

    void moveByDelta(Vector3 start, Vector3 delta, float moveTime) {
        float distDelta = Mathfx.Hermite(0, 1, totalTime / moveTime) - distanceMoved;
        Vector3 deltaPos = Quaternion.AngleAxis(headset.gameObject.transform.localEulerAngles.y, Vector3.up) * (delta * distDelta);
        transform.position += transform.rotation * deltaPos;
        totalTime += Time.deltaTime;
        distanceMoved += distDelta;
    }
}
*/