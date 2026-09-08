using UnityEngine;

namespace Marrowmark
{
    /// <summary>
    /// Step 1 of tech.md §6: move and look.
    ///
    /// Nothing from the game design is in here yet — this is the tutorial
    /// step, and its only job is to put a body in a room that you can walk
    /// around. Stamina, dodging and combat arrive in steps 2 onward, and
    /// they will come from the Marrowmark.Sim library rather than from this
    /// file.
    ///
    /// Attach to a capsule with a CharacterController component.
    /// </summary>
    [RequireComponent(typeof(CharacterController))]
    public class PlayerController : MonoBehaviour
    {
        [Header("Movement")]
        [Tooltip("Metres per second at a walk.")]
        public float walkSpeed = 3.5f;

        [Tooltip("Metres per second while holding sprint.")]
        public float sprintSpeed = 6.5f;

        [Tooltip("How quickly the character turns to face where it is going.")]
        public float turnSpeed = 12f;

        [Header("Gravity")]
        [Tooltip("Downward acceleration. Earth is -9.81; games usually want more.")]
        public float gravity = -20f;

        // The CharacterController is Unity's built-in "capsule that walks
        // and does not fall through floors". We ask for it in
        // RequireComponent above so Unity adds one automatically.
        private CharacterController _controller;

        // Vertical speed, tracked separately from horizontal movement so
        // gravity can accumulate frame over frame.
        private float _fallSpeed;

        private Transform _camera;

        private void Awake()
        {
            _controller = GetComponent<CharacterController>();

            // Camera.main finds the camera tagged "MainCamera". We move
            // relative to where the camera is looking, so that pushing the
            // stick forward means "away from me" rather than "north".
            if (Camera.main != null) _camera = Camera.main.transform;
        }

        private void Update()
        {
            // ── Read input ──────────────────────────────────────────────
            // GetAxisRaw gives -1, 0 or 1 with no smoothing, which keeps
            // the controls crisp. Works for both WASD and a gamepad's left
            // stick out of the box.
            var input = new Vector3(
                Input.GetAxisRaw("Horizontal"),
                0f,
                Input.GetAxisRaw("Vertical"));

            // Normalise so diagonal movement is not faster than straight.
            if (input.sqrMagnitude > 1f) input.Normalize();

            // ── Turn input into a world direction ───────────────────────
            var move = input;
            if (_camera != null && input.sqrMagnitude > 0.001f)
            {
                // Flatten the camera's forward and right onto the ground
                // plane, or looking up a hill would slow you down.
                var forward = _camera.forward;
                var right = _camera.right;
                forward.y = 0f;
                right.y = 0f;
                forward.Normalize();
                right.Normalize();

                move = forward * input.z + right * input.x;
            }

            // ── Face the direction of travel ────────────────────────────
            if (move.sqrMagnitude > 0.001f)
            {
                var wanted = Quaternion.LookRotation(move);
                transform.rotation = Quaternion.Slerp(
                    transform.rotation, wanted, turnSpeed * Time.deltaTime);
            }

            // ── Gravity ─────────────────────────────────────────────────
            if (_controller.isGrounded && _fallSpeed < 0f)
            {
                // A small downward force while grounded keeps the
                // controller pressed against the floor. Exactly zero makes
                // isGrounded flicker on slopes.
                _fallSpeed = -2f;
            }
            else
            {
                _fallSpeed += gravity * Time.deltaTime;
            }

            // ── Move ────────────────────────────────────────────────────
            var speed = Input.GetKey(KeyCode.LeftShift) || Input.GetButton("Fire3")
                ? sprintSpeed
                : walkSpeed;

            var velocity = move * speed;
            velocity.y = _fallSpeed;

            // Multiplying by deltaTime makes movement frame-rate
            // independent — the same idea as passing deltaSeconds into the
            // simulation library.
            _controller.Move(velocity * Time.deltaTime);
        }
    }
}
