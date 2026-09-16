extends Node
## Which way the player is holding the game, right now.
##
## Autoloaded as `InputMode`, so it survives scene changes and sees every
## event before any scene consumes one.
##
## **The scheme follows the last thing you actually used, not the
## platform.** Platform only chooses the opening guess. A phone with a
## pad plugged in is a pad game; unplug it mid-session and the thumb
## controls come back without a menu, a restart, or a question. A laptop
## with a touchscreen is a keyboard game until somebody touches the
## screen. Asking the player to declare their hardware is the thing this
## exists to avoid — `interface.md` §1 puts the world first, and a
## settings screen about controllers is the opposite of that.
##
## Nothing here consumes input or changes what a press does. It only
## answers "which prompts and which on-screen controls belong on screen",
## and shouts when the answer changes.

signal scheme_changed(scheme: int)

enum { PAD, TOUCH, KEYBOARD }

## Deliberately higher than the gameplay dead zones (0.15–0.18). This
## decides whether to *redraw the interface*, so a worn stick resting
## off-centre must not flip the scheme back and forth while the player is
## typing.
const PAD_WAKE := 0.45

## A mouse that moves less than this is a knock to the desk.
const MOUSE_SLOP := 6.0

## Godot can synthesise mouse events from touches, and some browsers do
## it regardless. Within this long after a real touch, mouse events are
## assumed to be that echo rather than a hand on a mouse.
const TOUCH_ECHO_MSEC := 1500

var _scheme := KEYBOARD
var _last_touch_msec := -1000000


func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	_scheme = _opening_guess()
	Input.joy_connection_changed.connect(_on_pad_changed)


func scheme() -> int:
	return _scheme


func is_pad() -> bool:
	return _scheme == PAD


func is_touch() -> bool:
	return _scheme == TOUCH


func is_keyboard() -> bool:
	return _scheme == KEYBOARD


## For anything that has to name it on screen.
func scheme_name() -> String:
	match _scheme:
		PAD: return "controller"
		TOUCH: return "touch"
		_: return "keyboard"


## True where an on-screen control could ever be wanted. A desktop with a
## touchscreen counts; a phone always counts.
func touch_possible() -> bool:
	return DisplayServer.is_touchscreen_available()


func pad_connected() -> bool:
	return not Input.get_connected_joypads().is_empty()


## The name of the pad in hand, or "" — the launcher reports this, and it
## is the one piece of hardware detail worth showing a player.
func pad_name() -> String:
	var pads := Input.get_connected_joypads()
	return Input.get_joy_name(pads[0]) if not pads.is_empty() else ""


func _opening_guess() -> int:
	if pad_connected():
		return PAD
	if touch_possible():
		return TOUCH
	return KEYBOARD


func _set_scheme(s: int) -> void:
	if s == _scheme:
		return
	_scheme = s
	scheme_changed.emit(s)


## A pad appearing takes over; a pad leaving hands back to whatever the
## machine has. This is the case the player asked about out loud: the
## controller comes out of the socket and the thumb controls should be
## there, not a dead screen.
func _on_pad_changed(_device: int, connected: bool) -> void:
	if connected:
		_set_scheme(PAD)
	elif _scheme == PAD:
		_set_scheme(TOUCH if touch_possible() else KEYBOARD)


func _input(event: InputEvent) -> void:
	# _input, not _unhandled_input: a focused button eats the A press that
	# would otherwise be the clearest evidence a pad is in use, and it eats
	# it before _unhandled_input runs.
	if event is InputEventScreenTouch or event is InputEventScreenDrag:
		_last_touch_msec = Time.get_ticks_msec()
		_set_scheme(TOUCH)
		return

	if event is InputEventJoypadButton:
		if (event as InputEventJoypadButton).pressed:
			_set_scheme(PAD)
		return

	if event is InputEventJoypadMotion:
		if absf((event as InputEventJoypadMotion).axis_value) >= PAD_WAKE:
			_set_scheme(PAD)
		return

	if event is InputEventKey:
		var k := event as InputEventKey
		if k.pressed and not k.echo:
			_set_scheme(KEYBOARD)
		return

	# Mouse last, and only once nothing else explains it. Godot's own
	# touch-to-mouse emulation labels its events, and it fires them
	# BEFORE the touch, so the time window below cannot catch them —
	# the device id is the only thing that can.
	if event is InputEventMouse \
			and (event as InputEventMouse).device == InputEvent.DEVICE_ID_EMULATION:
		return
	# A browser synthesising its own mouse events from touches does not
	# label them; those arrive after, so the window does catch them.
	if Time.get_ticks_msec() - _last_touch_msec < TOUCH_ECHO_MSEC:
		return
	if event is InputEventMouseButton:
		if (event as InputEventMouseButton).pressed:
			_set_scheme(KEYBOARD)
	elif event is InputEventMouseMotion:
		if (event as InputEventMouseMotion).relative.length() >= MOUSE_SLOP:
			_set_scheme(KEYBOARD)
