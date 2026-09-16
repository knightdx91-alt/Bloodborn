extends Node
## Does Thornfield remember?

var _fails: Array[String] = []


func _ok(n: String, c: bool, d: String) -> void:
	if c: print("  ok    %s" % n)
	else: _fails.append(n); print("  FAIL  %s — %s" % [n, d])


func _settle() -> void:
	for i in 4: await get_tree().process_frame


func _ready() -> void:
	TownState.reset()
	await _settle()

	var a: TownWorldState = TownState.current()
	_ok("a fresh town has taken nothing", a.contracts_taken.is_empty(),
		"started with %d" % a.contracts_taken.size())
	var start_coin: int = a.coin

	# Do things a player does.
	var id := String(Boards.contracts(a)[0]["id"])
	Boards.take(a, id)
	Apprenticeship.hire(a, "odo")
	a.coin -= 3
	a.boar_pressure["the Hedges west"] = 1
	TownState.save()
	await _settle()

	# Now forget everything in memory, as leaving for the drill yard and
	# coming back used to do — and as closing the app really does.
	TownState._state = null
	var b: TownWorldState = TownState.current()

	_ok("the contract survives", b.contracts_taken.has(id),
		"contracts_taken is %s" % str(b.contracts_taken))
	_ok("the apprenticeship survives", b.hired and b.apprentice_master == "odo",
		"hired=%s master='%s'" % [str(b.hired), b.apprentice_master])
	_ok("the purse survives", b.coin == start_coin - 3,
		"coin is %d, expected %d" % [b.coin, start_coin - 3])
	_ok("a nested value survives", int(b.boar_pressure["the Hedges west"]) == 1,
		"pressure is %s" % str(b.boar_pressure))

	# And the board reads the remembered state, not a fresh one.
	var still_taken := false
	for r in Boards.contracts(b):
		if String(r["id"]) == id and bool(r["taken"]):
			still_taken = true
	_ok("the board agrees it is taken", still_taken,
		"the board offers '%s' as free" % id)

	# Every field is covered, so a field added later is not silently lost.
	var named: Array = []
	for p in TownWorldState.new().get_property_list():
		if int(p["usage"]) & PROPERTY_USAGE_SCRIPT_VARIABLE:
			named.append(String(p["name"]))
	var cfg := ConfigFile.new()
	cfg.load(TownState.PATH)
	var missing: Array = []
	for f in named:
		if not cfg.has_section_key(TownState.SECTION, f):
			missing.append(f)
	_ok("every field on the state is written down", missing.is_empty(),
		"not saved: %s" % ", ".join(missing))

	TownState.reset()
	print("")
	print("persistence: all clear" if _fails.is_empty() else "FAILED: %s" % ", ".join(_fails))
	get_tree().quit()
