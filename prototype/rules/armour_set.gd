class_name ArmourSet
extends RefCounted
## A harness: four slots, each with its own condition. design/combat.md §4
## and pillars.md L62/L63.
##
## Mirrors sim/Marrowmark.Sim/Items/ArmorSet.cs and the damage triangle in
## Combat/DamageTable.cs — see stamina.gd for why the duplication exists.
## The numbers are NOT duplicated: they come out of combat.json, and
## DamageTableFileTests fails the build if the two copies disagree.
##
## L63: "a piece that breaks does not merely stop protecting — **it comes
## off**, and that slot is bare for the rest of the fight." Which piece
## fails is therefore a record of how its owner was fought, which is what
## L64's arcs are for.

enum Slot { HEAD, TORSO, ARMS, LEGS }

const CLASS_NAMES := ["none", "light", "mail", "plate"]
const TYPE_NAMES := ["cut", "pierce", "blunt"]

var _table: Dictionary
var _armour: Dictionary
var _class_of := {}      ## Slot -> class name while the piece is worn
var _condition := {}
var _max := 100.0

func _init(armour_class: String = "mail") -> void:
	_table = Tuning.load_section("damageTable")
	_armour = Tuning.load_section("armour")
	_max = _armour.get("maxCondition", 100.0)
	for slot in [Slot.HEAD, Slot.TORSO, Slot.ARMS, Slot.LEGS]:
		_class_of[slot] = armour_class.to_lower()
		_condition[slot] = _max

## What is actually protecting a slot. A broken piece protects nothing,
## because it is no longer there.
func protection_at(slot: int) -> String:
	return _class_of[slot] if is_worn(slot) else "none"

func is_worn(slot: int) -> bool:
	return _condition[slot] > 0.0

func condition_at(slot: int) -> float:
	return _condition[slot] / _max

func intact_pieces() -> int:
	var n := 0
	for slot in _condition:
		if is_worn(slot): n += 1
	return n

func is_stripped() -> bool:
	return intact_pieces() == 0

## Which piece a blow along this arc meets. L64.
##
## Nothing routes to the arms: arms are what you raise, so vambraces wear
## from *blocking* rather than from being aimed at. A sword-arm that gives
## out because you parried all day is the most grounded failure this
## system can produce.
static func slot_for(direction: int) -> int:
	match direction:
		Attack.Arc.OVERHEAD: return Slot.HEAD
		Attack.Arc.LOWER_LEFT, Attack.Arc.LOWER_RIGHT: return Slot.LEGS
		_: return Slot.TORSO

static func location_of(slot: int) -> String:
	match slot:
		Slot.HEAD: return "head"
		Slot.ARMS, Slot.LEGS: return "limb"
		_: return "torso"

## Resolve a blow. Returns { damage, slot, broke, bare } — `broke` is true
## only on the blow that takes the piece off, which is the moment L63
## cares about.
func resolve(slot: int, weapon_damage: float, damage_type: String = "cut",
		wear: float = -1.0) -> Dictionary:
	var armour_class := protection_at(slot)
	var against: float = _table.get(damage_type, {}).get(armour_class, 1.0)
	var where: float = _table.get(location_of(slot), 1.0)

	var broke := false
	if wear < 0.0:
		wear = _armour.get("wearPerHit", 11.0)
	if wear > 0.0 and is_worn(slot):
		_condition[slot] = max(0.0, _condition[slot] - wear)
		broke = _condition[slot] <= 0.0

	return {
		"damage": weapon_damage * against * where,
		"slot": slot,
		"broke": broke,
		"bare": armour_class == "none",
	}

func reset() -> void:
	for slot in _condition:
		_condition[slot] = _max
