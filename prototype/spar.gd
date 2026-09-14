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
var w: Node3D

func _fight(seconds: int, plan: Array, seed_value: int) -> Dictionary:
	w.player.revive(); w.player.position = w.PLAYER_HOME
	w.enemy.revive(); w.enemy.position = w.ENEMY_HOME
	w._player_down = 0.0; w._enemy_down = 0.0
	w.tactics = EnemyTactics.new(seed_value)
	for i in 3: await get_tree().physics_frame

	var taken := 0.0
	var dealt := 0.0
	var deaths := 0
	var kills := 0
	var parried := 0
	var openings := 0
	var last_p: float = w.player.health.current()
	var last_e: float = w.enemy.health.current()
	var before_parries: int = w._parries

	for i in seconds * 60:
		await get_tree().physics_frame
		var p: float = w.player.health.current()
		if p < last_p: taken += last_p - p
		elif p > last_p: deaths += 1
		last_p = p
		var e: float = w.enemy.health.current()
		if e < last_e: dealt += last_e - e
		elif e > last_e: kills += 1
		last_e = e

		if w.player.is_busy() or w._player_down > 0.0 or w._enemy_down > 0.0:
			continue

		# Defend first, per the plan.
		if w.enemy.attack.phase() == 1:
			var shape: int = w.enemy.attack.shape()
			var left: float = w.enemy.attack.windup_seconds() - w.enemy.attack.elapsed()
			match plan[shape]:
				"parry":
					if left < 0.20 and w.player.parry.can_act():
						w.player.try_parry(); continue
				"dodge":
					if left < 0.12 and w.player.dodge.can_act():
						w.player.try_dodge(Vector3(1, 0, 0)); continue
				"around":
					# L56: "a dodge repositions, it does not merely evade.
					# Dodging toward, around and through are all real
					# options, so exchanges circle." Dodge across him
					# rather than away, and stay in reach.
					if left < 0.12 and w.player.dodge.can_act():
						var at: Vector3 = w.enemy.global_position - w.player.global_position
						at.y = 0.0
						w.player.try_dodge(at.normalized().cross(Vector3.UP)); continue
				"away":
					if left < 0.45 and w.player.dodge.can_act():
						var away: Vector3 = w.player.global_position - w.enemy.global_position
						away.y = 0.0
						w.player.try_dodge(away.normalized()); continue

		# Disciplined: strike into openings only, never on spec. That is
		# what isolates the value of parrying — a bot that swings freely
		# drowns the defensive choice in its own aggression, which is how
		# the first version of this measured nothing.
		var to: Vector3 = w.enemy.global_position - w.player.global_position
		to.y = 0.0
		var heading: Vector3 = to.normalized()
		w.player.rotation.y = atan2(-heading.x, -heading.z)
		var open: bool = w.enemy.is_staggered() or w.enemy.attack.phase() == 3
		if not open:
			continue
		if to.length() > 1.5:
			w.player.move(heading, 3.4, 1.0 / 60.0)
		else:
			w.player.try_attack()
			openings += 1
	parried = w._parries - before_parries
	return {"taken": taken, "dealt": dealt, "deaths": deaths, "kills": kills,
		"parried": parried, "openings": openings}

func _ready() -> void:
	w = (load("res://main.tscn") as PackedScene).instantiate()
	add_child(w)
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
