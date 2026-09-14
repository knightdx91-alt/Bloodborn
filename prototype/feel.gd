class_name Feel
extends RefCounted
## What a blow feels like — hitstop and the camera.
##
## `art-audio.md` §2: **"The camera is a participant. Framing, shake and
## depth of field are information channels — an exhausted character's
## camera behaves differently. Cheap, and it does work no HUD element is
## allowed to."** This is that, taken up.
##
## ⚠️ **Everything here is presentation and none of it touches the
## rules.** `combat.md` §7 makes damage server-authoritative and
## defensive windows client-authoritative inside a tolerance envelope; a
## freeze that stopped the phase machines would mean the 0.28s parry
## window was not 0.28s on the client, and the server would be
## adjudicating against timings the player never experienced. So hitstop
## pauses *animation*, and the stamina, dodge, attack and parry clocks
## carry on at real speed.

## How long the world hesitates on a blow, by how heavy it was. Short:
## this is a punctuation mark, and past about a tenth of a second it
## stops reading as impact and starts reading as a dropped frame.
const STOP_BASE := 0.040
const STOP_PER_WEIGHT := 0.036
const STOP_PARRY := 0.10

const KICK_DECAY := 9.0
const SHAKE_DECAY := 11.0
const BREATH_SPEED := 2.4

var _kick := Vector3.ZERO
var _shake := 0.0
var _breath := 0.0
var _t := 0.0

## Seconds of hesitation for a blow of this weight (1.0 being a plain
## sword cut).
static func hitstop_for(weight: float) -> float:
	return STOP_BASE + STOP_PER_WEIGHT * weight

## Shove the camera along the blow. The direction is the blow's, so a hit
## taken from the left throws the view right — the camera flinches with
## the body rather than at it.
func kick(direction: Vector3, strength: float) -> void:
	var flat := Vector3(direction.x, 0.0, direction.z)
	if flat.length() > 0.001:
		_kick += flat.normalized() * strength
	_shake = maxf(_shake, strength * 0.55)

## A rattle with no direction — a parry, a guard breaking.
func shake(amount: float) -> void:
	_shake = maxf(_shake, amount)

## How hard the fighter is breathing, 0..1. combat.md §2 makes stamina
## the whole economy and interface.md §2 refuses a bar for anyone else,
## so the camera saying it is a real channel rather than a flourish.
func breathe(amount: float) -> void:
	_breath = clamp(amount, 0.0, 1.0)

func tick(delta: float) -> void:
	_t += delta
	_kick = _kick.lerp(Vector3.ZERO, clamp(KICK_DECAY * delta, 0.0, 1.0))
	_shake = move_toward(_shake, 0.0, SHAKE_DECAY * delta * maxf(_shake, 0.1))

## Where the camera should sit relative to where it would otherwise.
func offset() -> Vector3:
	var out := _kick
	if _shake > 0.0001:
		# Deterministic rather than random: a fight replayed from the same
		# inputs should look the same, and sin() is cheaper than a
		# generator nobody seeded.
		out += Vector3(
			sin(_t * 91.0) * _shake,
			sin(_t * 73.0 + 1.7) * _shake * 0.7,
			sin(_t * 67.0 + 3.1) * _shake * 0.5)
	if _breath > 0.0:
		# Slow, shallow, and only when the bar is nearly gone.
		var sway := sin(_t * BREATH_SPEED) * 0.035 * _breath
		out += Vector3(sway * 0.4, sway, 0.0)
	return out
