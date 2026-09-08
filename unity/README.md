# Unity — staging folder

Scripts written here before the Unity project exists, or before they
can be verified in it. **Copy them into `game/Assets/Scripts/` once the
project is created.**

They are written but **not compiled** — there is no Unity in the
environment they were authored in. Expect to fix the first error or two
together; that is normal and not a sign anything is wrong.

---

## Step 1 — move and look

`tech.md` §6 Stage 1, step 1. Nothing from the game design is in this
step: it exists to put a body in a room you can walk around, and to be
the thing you learn Unity on.

### Setting it up

**Before anything else** — Edit → Project Settings → Player → **Active
Input Handling → "Both"**. These scripts use the classic input API, and
a project set to the new Input System alone will throw at runtime.

1. **Make a floor.** GameObject → 3D Object → Plane. Set its Scale to
   `(5, 1, 5)` so there is room to walk.
2. **Make the player.** GameObject → 3D Object → Capsule. Rename it
   `Player`. Set its Position to `(0, 1, 0)`.
   - Remove the **Capsule Collider** it came with (right-click the
     component → Remove Component). The CharacterController brings its
     own.
   - Add Component → **Character Controller**.
   - Add Component → **Player Controller** (the script).
3. **Point the camera at it.** Select the **Main Camera** in the
   hierarchy.
   - Add Component → **Orbit Camera** (the script).
   - Drag the `Player` object from the hierarchy into the script's
     **Target** field.
4. **Press Play.** WASD or the left stick to move, mouse or the right
   stick to look, Shift to sprint, Escape to release the cursor.

### What you should see

A capsule that walks around a plane, turns to face where it is going,
and stays on the floor. A camera that orbits it and pulls in when a
wall gets between you.

**That is the whole step.** It is not a game, and it is not meant to
be — it is the first time the project has been a thing that runs.

### If something goes wrong

- **"The name 'Input' does not exist"** or input errors at runtime →
  Active Input Handling is not set to "Both". See above.
- **Capsule falls through the floor** → the Plane has no collider, or
  the player kept its Capsule Collider alongside the
  CharacterController.
- **Camera does not move** → the Target field is empty, or the camera
  is not tagged `MainCamera`.
- **Nothing happens on Play** → check the Console tab for a compile
  error; nothing runs while one exists.

### Next

Step 2 is the dodge — the first thing in this project that comes from
the design (`combat.md` §1). That one gets its numbers from the
simulation library rather than from a field in the inspector.
