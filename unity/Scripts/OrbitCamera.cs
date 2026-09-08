using UnityEngine;

namespace Marrowmark
{
    /// <summary>
    /// A third-person camera that orbits a target.
    ///
    /// Deliberately plain. `combat.md` §2 eventually wants the camera to be
    /// a participant — framing and shake carrying information no HUD is
    /// allowed to (L80/L84) — but none of that belongs in step 1.
    ///
    /// Attach to the Main Camera and drag the player into `target`.
    /// </summary>
    public class OrbitCamera : MonoBehaviour
    {
        [Header("Target")]
        public Transform target;

        [Tooltip("Height above the target's origin to look at — roughly the chest.")]
        public float targetHeight = 1.4f;

        [Header("Orbit")]
        public float distance = 4.5f;
        public float sensitivity = 3f;

        [Tooltip("How far the camera may look down and up, in degrees.")]
        public float minPitch = -30f;
        public float maxPitch = 70f;

        [Header("Collision")]
        [Tooltip("Pull the camera in when a wall is between it and the target.")]
        public bool avoidWalls = true;
        public LayerMask wallLayers = ~0;

        private float _yaw;
        private float _pitch = 15f;

        private void Start()
        {
            // Hide and lock the cursor so mouse movement turns the camera
            // instead of running off the screen. Press Escape to release it
            // while testing in the editor.
            Cursor.lockState = CursorLockMode.Locked;
            Cursor.visible = false;
        }

        // LateUpdate runs after every Update, so the player has already
        // moved this frame. Cameras belong here — following in Update
        // produces a one-frame lag that reads as jitter.
        private void LateUpdate()
        {
            if (target == null) return;

            if (Input.GetKeyDown(KeyCode.Escape))
            {
                Cursor.lockState = CursorLockMode.None;
                Cursor.visible = true;
            }

            // Mouse, plus the right stick if a gamepad is connected.
            _yaw += Input.GetAxis("Mouse X") * sensitivity;
            _pitch -= Input.GetAxis("Mouse Y") * sensitivity;
            _pitch = Mathf.Clamp(_pitch, minPitch, maxPitch);

            var rotation = Quaternion.Euler(_pitch, _yaw, 0f);
            var focus = target.position + Vector3.up * targetHeight;

            // Start at the focus point and walk backwards along the
            // camera's own forward axis.
            var wanted = focus - rotation * Vector3.forward * distance;

            if (avoidWalls &&
                Physics.Linecast(focus, wanted, out var hit, wallLayers,
                                 QueryTriggerInteraction.Ignore))
            {
                // Something solid is in the way — sit just in front of it.
                wanted = hit.point + hit.normal * 0.2f;
            }

            transform.position = wanted;
            transform.rotation = rotation;
        }
    }
}
