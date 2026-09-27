extends Node3D
## A sparring bot, and a tuning instrument. Fights the same seeded enemy
## several ways and reports what each is worth.
##
##     godot --path prototype --headless --fixed-fps 60 spar.tscn
##
## It exists to answer one question after any tuning change: **is one
## answer strictly better than the others?** combat.md §6 promises three
## shapes with three answers, and that promise is falsifiable.
##
## ⚠️ **It cannot tell you whether anything feels good.** §9 is explicit
## that feel is judged with a controller, and this bot is frame-perfect —
## it parries 0.22s wind-ups no human could read. Treat it as a ceiling,
## not a player.
##
## **Two ways this measured nothing before it measured something**, both
## worth knowing before trusting a run of it:
##
## 1. It only counted damage TAKEN. Under that metric a bot that never
##    tries to win is optimal, and "dodge everything" looked dominant —
##    the boxer who runs away, declared champion. It now counts kills.
## 2. The bot swung freely, so the defensive choice drowned in its own
##    aggression: four parries in eighty seconds explained nothing. It
##    now strikes into openings only, which is what the design is about.
var yard: DrillYard
var field: Skirmish
var player: Fighter
var _parries := 0

const PLAYER_HOME := Vector3(0, 1, 2)
const PLAYER_HEALTH := 100.0
const SWORD_DAMAGE := 28.0


## The rig: a floor, a fighter, one Skirmish, and the REAL drill yard.
##
## This used to load main.tscn and reach into it by name — the player,
## the respawn timers, the tactics, the parry tally — which made a tuning
## instrument depend on one scene's private fields. That scene is gone.
##
## What replaces it is better than a port. `DrillYard` is a region now,
## so the bot can stand up the actual yard, with the actual swordsman on
## the actual EnemyTactics, driven by the actual `_run` the game uses —
## without a town, a sky, a clock or a camera. The thing being measured
## is the thing that ships, which was not quite true before: the old rig
## measured the yard scene, and the yard scene is not where the game is
## played any more.
func _rig() -> void:
	var ground := StaticBody3D.new()
	var col := CollisionShape3D.new()
	var box := BoxShape3D.new()
	box.size = Vector3(200.0, 0.4, 200.0)
	col.shape = box
	col.position = Vector3(0, -0.2, 0)
	ground.add_child(col)
	add_child(ground)

	field = Skirmish.new()
	field.name = "Skirmish"
	add_child(field)
	field.parried.connect(func(_a: Fighter, _v: Fighter) -> void: _parries += 1)

	player = Fighter.new()
	player.position = PLAYER_HOME
	add_child(player)
	player.setup(PLAYER_HEALTH, Color.WHITE, true, Fighter.CHARACTER,
		Look.IRON, Look.LEATHER, "mail")
	player.weapon_damage = SWORD_DAMAGE
	field.enlist(player)

	yard = DrillYard.new()
	add_child(yard)
	yard.sparred_by(player, field)


func _fight(seconds: int, plan: Array, seed_value: int) -> Dictionary:
	player.revive(); player.position = PLAYER_HOME
	yard.swordsman.revive(); yard.swordsman.position = DrillYard.SWORDSMAN_HOME
	yard.tactics = EnemyTactics.new(seed_value)
	yard.respawn_seed = seed_value
	for i in 3: await get_tree().physics_frame

	var taken := 0.0
	var dealt := 0.0
	var deaths := 0
	var kills := 0
	var parried := 0
	var openings := 0
	var last_p: float = player.health.current()
	var last_e: float = yard.swordsman.health.current()
	var before_parries: int = _parries

	for i in seconds * 60:
		await get_tree().physics_frame
		# TICK THE BOT.
		#
		# Fighter does not tick itself — whoever owns one drives it, so
		# the yard ticks its swordsman and TownWalker ticks itself. The
		# player here is owned by this rig and by nothing else, and the
		# first version forgot: every state machine stayed frozen at the
		# first frame, `is_busy()` never cleared, and all five plans
		# reported identically to the decimal because the bot did
		# literally nothing in any of them. Identical results across
		# plans that should differ is what that looks like from outside.
		player.tick(1.0 / 60.0)
		var p: float = player.health.current()
		if p < last_p: taken += last_p - p
		elif p > last_p: deaths += 1
		last_p = p
		var e: float = yard.swordsman.health.current()
		if e < last_e: dealt += last_e - e
		elif e > last_e: kills += 1
		last_e = e

		# PUT THE BOT BACK ON ITS FEET.
		#
		# world.gd owned this: it ran the respawn timers for both bodies
		# and revived them. The yard revives the swordsman itself, but
		# nobody revives the player outside the town — so the first
		# version of this rig died once and lay there, and reported all
		# five plans as identical to the decimal, which is what a bot
		# that never acts again looks like.
		if player.health.is_dead():
			player.revive()
			player.position = PLAYER_HOME
			continue
		if player.is_busy() or yard.swordsman.health.is_dead():
			continue

		# Defend first, per the plan.
		if yard.swordsman.attack.phase() == 1:
			var shape: int = yard.swordsman.attack.shape()
			var left: float = yard.swordsman.attack.windup_seconds() - yard.swordsman.attack.elapsed()
			match plan[shape]:
				"parry":
					if left < 0.20 and player.parry.can_act():
						player.try_parry(); continue
				"dodge":
					if left < 0.12 and player.dodge.can_act():
						player.try_dodge(Vector3(1, 0, 0)); continue
				"around":
					# L56: "a dodge repositions, it does not merely evade.
					# Dodging toward, around and through are all real
					# options, so exchanges circle." Dodge across him
					# rather than away, and stay in reach.
					if left < 0.12 and player.dodge.can_act():
						var at: Vector3 = yard.swordsman.global_position - player.global_position
						at.y = 0.0
						player.try_dodge(at.normalized().cross(Vector3.UP)); continue
				"away":
					if left < 0.45 and player.dodge.can_act():
						var away: Vector3 = player.global_position - yard.swordsman.global_position
						away.y = 0.0
						player.try_dodge(away.normalized()); continue

		# Disciplined: strike into openings only, never on spec. That is
		# what isolates the value of parrying — a bot that swings freely
		# drowns the defensive choice in its own aggression, which is how
		# the first version of this measured nothing.
		var to: Vector3 = yard.swordsman.global_position - player.global_position
		to.y = 0.0
		var heading: Vector3 = to.normalized()
		player.rotation.y = atan2(-heading.x, -heading.z)
		var open: bool = yard.swordsman.is_staggered() or yard.swordsman.attack.phase() == 3
		if not open:
			continue
		if to.length() > 1.5:
			player.move(heading, 3.4, 1.0 / 60.0)
		else:
			player.try_attack()
			openings += 1
	parried = _parries - before_parries
	return {"taken": taken, "dealt": dealt, "deaths": deaths, "kills": kills,
		"parried": parried, "openings": openings}

func _ready() -> void:
	_rig()
	for i in 8: await get_tree().physics_frame

	var plans := {
		"dodge everything   ": ["dodge", "dodge", "dodge"],
		"§6's answers       ": ["dodge", "parry", "away"],
		"parry all you can  ": ["parry", "parry", "away"],
		"dodge AROUND him   ": ["around", "around", "around"],
		"§6, dodging around ": ["around", "parry", "away"],
	}
	const SECONDS := 40
	var seeds := [11, 4242, 77, 31337]
	print("%d seconds per run, %d seeds, same enemy behaviour each time" % [SECONDS, seeds.size()])
	for name in plans:
		var dealt := 0.0
		var taken := 0.0
		var kills := 0
		var deaths := 0
		var parried := 0
		var openings := 0
		for s in seeds:
			var r: Dictionary = await _fight(SECONDS, plans[name], s)
			dealt += r["dealt"]; taken += r["taken"]
			kills += r["kills"]; deaths += r["deaths"]; parried += r["parried"]
			openings += r["openings"]
		print("%s kills %2d  deaths %d  dealt %5.0f  taken %5.0f  parried %2d  swings into openings %3d" % [
			name, kills, deaths, dealt, taken, parried, openings])
	get_tree().quit()
