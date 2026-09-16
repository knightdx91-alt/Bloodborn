class_name Skirmish
extends Node3D
## Who can hit whom, and what happens when they do.
##
## This was the middle of `world.gd` — `_resolve_swing`, `_land` and
## `_impact`, reaching straight for that scene's `player`, `enemy` and
## `dummy`. That is why the town had no enemies: combat WORKED there the
## moment `TownWalker` became a `Fighter`, but nothing existed to notice
## a live blade passing through anybody, and nothing could, because the
## code that notices only knew how to look at one scene's three fields.
##
## Reported from play: *"i want the whole thing to just be a big world,
## where you can go to the arena, and where ever else from the main
## town."* One world means one combat, so this owns a LIST of fighters
## rather than a pair of names, and any region can put its own into it.
##
## The rules are still `sim/`'s. This is the geometry and the bookkeeping
## around them — reach, arc, who is on whose side, and what a blow does
## to the camera.

## Everyone who can swing or be swung at.
var fighters: Array[Fighter] = []
## Things that take hits but never give them — the training dummy.
var posts: Array = []

var feel: Feel = null
## Whose view gets kicked harder when they are the one being hit.
var watching: Fighter = null

var show_debug := false

signal landed_on_post(amount: float)


func enlist(who: Fighter) -> void:
	if who != null and not fighters.has(who):
		fighters.append(who)


func discharge(who: Fighter) -> void:
	fighters.erase(who)


## A thing that can be struck but does not fight back: { at, radius, on_hit }.
func add_post(at: Callable, radius: float) -> void:
	posts.append({"at": at, "radius": radius})


func _physics_process(_delta: float) -> void:
	# A copy, because a blow can kill somebody and a dead fighter may be
	# taken out of the list while it is being walked.
	for who in fighters.duplicate():
		if is_instance_valid(who):
			resolve(who)


## One fighter's live blade against everything else in the field.
##
## The blade is live for a tenth of a second and connects at most once,
## so this asks once and the swing is spent whatever else it passes
## through.
func resolve(who: Fighter) -> void:
	if not is_instance_valid(who) or not who.attack.is_active():
		return

	var facing: Vector3 = -who.global_transform.basis.z

	# Posts first: a dummy is what you are aiming at when one is there.
	for post in posts:
		var at: Vector3 = (post["at"] as Callable).call()
		var to_post: Vector3 = at - who.global_position
		to_post.y = 0.0
		var post_angle: float = rad_to_deg(facing.signed_angle_to(to_post, Vector3.UP))
		if not who.attack.reaches(to_post.length() - float(post["radius"]), post_angle):
			continue
		if not who.attack.try_consume_hit():
			return
		var weight: float = who.attack.damage_multiplier()
		_impact(who, null, to_post.normalized(), weight)
		landed_on_post.emit(who.weapon_damage * weight)
		return

	for other in fighters:
		if other == who or not is_instance_valid(other):
			continue
		if other.health.is_dead():
			continue
		var to_them: Vector3 = other.global_position - who.global_position
		to_them.y = 0.0
		var angle: float = rad_to_deg(facing.signed_angle_to(to_them, Vector3.UP))
		if not who.attack.reaches(to_them.length() - 0.5, angle):
			continue
		if not who.attack.try_consume_hit():
			return
		_land(who, other, who.weapon_damage * who.attack.damage_multiplier(),
			to_them.normalized(), who.attack.damage_multiplier())
		return


func _impact(attacker: Fighter, victim: Fighter, blow: Vector3, weight: float) -> void:
	var stop := Feel.hitstop_for(weight)
	attacker.freeze(stop)
	if victim != null:
		victim.freeze(stop)
	if feel == null:
		return
	# Taking one shoves the view harder than landing one.
	var strength: float = 0.05 + 0.055 * weight
	if victim != null and victim == watching:
		strength *= 1.8
	feel.kick(blow, strength)


func _land(attacker: Fighter, victim: Fighter, damage: float,
		blow: Vector3, weight: float) -> void:
	_impact(attacker, victim, blow, weight)

	# The guard gets first refusal. combat.md §6 makes parry the answer to
	# a heavy, and the committed attack unparryable — the rule for which
	# lives in sim/, not here.
	match victim.meet(attacker.attack, damage):
		Parry.Outcome.BLOCKED:
			# §1: a blocked blow still carries something through. Blocking
			# is a stamina war, never an off switch.
			var through: float = damage * victim.parry.blocked_fraction()
			victim.hurt(through, attacker.attack.arc)
			return
		Parry.Outcome.PARRIED:
			attacker.stagger(victim.parry.stagger_seconds())
			# A parry is a clang, not a shove: it rattles rather than
			# throwing the view, because nothing moved.
			attacker.freeze(Feel.STOP_PARRY)
			victim.freeze(Feel.STOP_PARRY)
			if feel != null:
				feel.shake(0.075)
			return
		Parry.Outcome.UNPARRYABLE, Parry.Outcome.TOO_EARLY, Parry.Outcome.TOO_LATE:
			pass

	var hit := victim.hurt(damage, attacker.attack.arc)

	# L87's load-bearing claim, made audible: what the blow hit is told by
	# how it SOUNDS, not by a number. `class` comes out of hurt() rather
	# than being asked of the harness afterwards — by then a piece that
	# broke on this blow reads "none".
	if hit["taken"] > 0.0:
		Sound.impact(self, victim.global_position + Vector3(0, 1.1, 0),
			String(hit["class"]))
