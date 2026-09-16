class_name Roster
extends RefCounted
## Thornfield's people: 9 conversational NPCs (voice cards carried in the
## authored lines) and ~25 bark crowd. Positions match town.gd's layout —
## NPCs stay where their work is (onboarding.md §5). Names are
## placeholders (lore.md §8).
##
## Topic dict: {topic, line, intent, effect, effect_arg}.
## Intent is validated against ConversationUI.INTENTS.

static func named() -> Array:
	return [
		{
			"id": "mara", "name": "Mara Kettle", "role": "innkeeper, The Sheaf",
			"voice": "Warm, fast, remembers everyone's drink; Thornfield burr.",
			"pos": Vector3(-14.5, 0, 2), "yaw": -PI / 2,
			"tunic": Color(0.55, 0.30, 0.22), "warm": true, "uses_name": false,
			"topics": [
				{"topic": "What's the talk?", "intent": "share_rumor", "effect": "ask_rumor",
					"line": "Talk? Oh, love, there's always talk. Here's the freshest of it — cost you nothing, this once."},
				{"topic": "A drink, then.", "intent": "offer_contract", "effect": "buy_drink",
					"line": "Two pennies, and I'll tell you what the drovers were saying before the foam settled. Drink's the search, love — everybody talks over ale."},
				{"topic": "Who's who in Thornfield?", "intent": "none", "effect": "",
					"line": "Odo beats metal west of the square, Pell runs the wagons south-west, Sarella keeps the chapel and the shrine. Fenwick minds the boards and his ink. Vance counts everything up the north road, Tammas brews it. And the quiet ones? The quiet ones are quiet."},
				{"topic": "Any work going?", "intent": "none", "effect": "open_contracts",
					"line": "Fenwick's boards, by the well. Cull work, wagon guards, harvest hands — the board never lies, love. If it's pinned, it's real."},
			],
		},
		{
			"id": "odo", "name": "Smith Odo", "role": "smith, apprenticeship master",
			"voice": "Slow, correcting, compliments work not people.",
			"pos": Vector3(-5.5, 0, -27.5), "yaw": -PI / 2,
			"tunic": Color(0.30, 0.28, 0.26), "warm": false, "uses_name": false,
			"topics": [
				{"topic": "Take me on.", "intent": "offer_contract", "effect": "hire", "effect_arg": "odo",
					"line": "Hands. Show me your hands. ... Soft. We'll fix that. I hire you, I teach you, I correct you — that's the whole of it."},
				{"topic": "Re-shoe the carter's pair?", "intent": "offer_contract", "effect": "take_contract", "effect_arg": "smith-1",
					"line": "Pell's lead pair throws shoes like excuses. Re-shoe them both. I'll check every nail."},
				{"topic": "Blunt the drill swords?", "intent": "offer_contract", "effect": "take_contract", "effect_arg": "smith-2",
					"line": "A dozen drill-yard swords want blunting. Blunt steel for the yard, sharp steel for the hedges — don't mix them up."},
				{"topic": "Teach me the drill yard.", "intent": "none", "effect": "",
					"line": "The yard's south-west, past my forge. Blunted steel, a partner who calls the arc before they throw it. Mind your left."},
			],
		},
		{
			"id": "pell", "name": "Carter Pell", "role": "carter, apprenticeship master",
			"voice": "Tired, funny, talks to horses mid-sentence.",
			"pos": Vector3(-22, 0, 31.5), "yaw": -PI / 2,
			"tunic": Color(0.35, 0.42, 0.30), "warm": true, "uses_name": false,
			"topics": [
				{"topic": "Take me on.", "intent": "offer_contract", "effect": "hire", "effect_arg": "pell",
					"line": "Ha! Another pair of hands — easy, girl, he means well — the Vellmark wagon musters at first light. You'll walk beside it and learn the harness."},
				{"topic": "Escort the Vellmark wagon?", "intent": "offer_contract", "effect": "take_contract", "effect_arg": "escort-velmark-1",
					"line": "Vellmark run's three days if the road's kind. It hasn't been kind. We want guards — steady — coin, not promises."},
				{"topic": "Escort the Greywater wagon?", "intent": "offer_contract", "effect": "take_contract", "effect_arg": "escort-greywater-1",
					"line": "Greywater wagon's short a guard. South road, good company, bad jokes. You'll do — shh, boy, you'll do."},
				{"topic": "Road news?", "intent": "share_rumor", "effect": "ask_rumor",
					"line": "Road news comes at caravan speed, friend — slow, and mostly about mud. But here's what reached me:"},
			],
		},
		{
			"id": "sarella", "name": "Gleaner Sarella", "role": "chapel hedge-priest",
			"voice": "Soft, omen-minded, speaks in seasons.",
			"pos": Vector3(12.5, 0, -30), "yaw": -PI / 2,
			"tunic": Color(0.35, 0.45, 0.30), "warm": true, "uses_name": false,
			"topics": [
				{"topic": "What is the shrine?", "intent": "none", "effect": "",
					"line": "The stone beside the chapel. When the worst happens out in the Hedges, the dying are knitted back there — never whole, and never free. The shrine keeps what it's owed. Come back poorer, come back wiser. That's the bottom rung of the ladder, and everyone climbs it."},
				{"topic": "First-fruits?", "intent": "none", "effect": "",
					"line": "Leave the first of anything at the altar — grain, apples, a thought. In Gleaner country a small wonder is just Tuesday. It's camouflage, mind, not protection."},
				{"topic": "Any omens?", "intent": "share_rumor", "effect": "ask_rumor",
					"line": "The seasons turn whether we read them or not. But since you ask — this is what the wind brought:"},
			],
		},
		{
			"id": "fenwick", "name": "Clerk Fenwick", "role": "clerk of the boards",
			"voice": "Precise, ink-stained, hates repeating himself.",
			"pos": Vector3(9.5, 0, 11), "yaw": 0.8,
			"tunic": Color(0.25, 0.25, 0.32), "warm": false, "uses_name": false,
			# He keeps the board, so he is who finished work is handed to.
			# A capability the CONTENT declares, rather than an id
			# hardcoded in the conversation layer — a second town has its
			# own clerk and should not have to be called Fenwick.
			"pays_contracts": true,
			"topics": [
				{"topic": "Show me the contracts.", "intent": "none", "effect": "open_contracts",
					"line": "The contract board. Cull, escort, harvest, smithing — all from the world as it is. Read it yourself; I don't repeat myself."},
				{"topic": "Show me the market board.", "intent": "none", "effect": "open_market",
					"line": "The market board. What Thornfield has warehoused: grain, cloth, ale, tools. Nothing else. I don't sell what isn't there."},
				{"topic": "What's the pay for cull work?", "intent": "none", "effect": "",
					"line": "It scales with the pressure — four pennies base, three more per point of it. The board states it plainly. I explain; I never mark. You want directions, ask someone with time."},
			],
		},
		{
			"id": "vance", "name": "Drover Vance", "role": "Vance farm",
			"voice": "Blunt, proud, counts everything.",
			"pos": Vector3(18, 0, 76), "yaw": 2.7,
			"tunic": Color(0.45, 0.38, 0.25), "warm": false, "uses_name": false,
			"topics": [
				{"topic": "A delivery, from Odo.", "intent": "none", "effect": "",
					"line": "Horseshoes? Let me count — twelve, fourteen... sixteen. Sixteen. Odo's shorted me twice before; he won't a third time. Tell him Vance counted."},
				{"topic": "Harvest work?", "intent": "offer_contract", "effect": "take_contract", "effect_arg": "harvest-vance",
					"line": "Four hands wanted. Maybe six. Wheat doesn't wait and neither do I. You work, you eat, you're paid — in that order."},
				{"topic": "How's the herd?", "intent": "none", "effect": "",
					"line": "Forty-one head this morning. Forty-one last night. Boars took two last week and I count twice a day now. Everything gets counted. Everything."},
			],
		},
		{
			"id": "tammas", "name": "Brewer Tammas", "role": "brewer",
			"voice": "Booming laugh, nose for gossip.",
			"pos": Vector3(17.5, 0, 29), "yaw": PI / 2,
			"tunic": Color(0.50, 0.32, 0.18), "warm": true, "uses_name": false,
			"topics": [
				{"topic": "Buying grain?", "intent": "none", "effect": "",
					"line": "Always buying! Good barley makes good ale makes good cheer — HA! Fenwick's board has the price. I just drink the profits."},
				{"topic": "Heard anything?", "intent": "share_rumor", "effect": "ask_rumor",
					"line": "Do I hear things? Friend, I hear everything — ale loosens every tongue but mine. Here's the latest:"},
				{"topic": "The ale's good.", "intent": "none", "effect": "",
					"line": "HA! Of course it is! Third vat from the left — that's the one. Tell Mara I said the foam's perfect today. She won't believe you."},
			],
		},
		{
			"id": "mira", "name": "Mira", "role": "the Sheaf's quiet corner",
			"voice": "Says little. The Open Vein's eyes in Thornfield — never stated.",
			"pos": Vector3(-15.5, 0, 6.5), "yaw": -PI / 2,
			"tunic": Color(0.30, 0.30, 0.34), "warm": false, "uses_name": false,
			"topics": [
				{"topic": "You watching me?", "intent": "set_disposition", "effect": "", "effect_arg": {"warm": false},
					"line": "Watching the door. Doors are interesting. People come through them changed, sometimes. ... Forget I said that."},
				{"topic": "Quiet night.", "intent": "none", "effect": "",
					"line": "... Mm."},
			],
		},
		{
			"id": "lamp", "name": "The Lamp's clerk", "role": "unremarkable traveler",
			"voice": "Dull on purpose. The Office of the Lamp notices; says nothing.",
			"pos": Vector3(5, 0, 4), "yaw": 2.5,
			"tunic": Color(0.38, 0.38, 0.38), "warm": false, "uses_name": false,
			"topics": [
				{"topic": "Passing through?", "intent": "none", "effect": "",
					"line": "Mm. Market day. Bought nails. Leaving tomorrow. Weather's been... weather."},
				{"topic": "What do you do?", "intent": "none", "effect": "",
					"line": "Paperwork. Ledgers. Nothing you'd find interesting. Nothing anyone would."},
			],
		},
	]


## The bark crowd: ~25, where their work is.
static func crowd() -> Array:
	var out: Array = []
	_add(out, "market", "market", [
		Vector3(6, 0, -3), Vector3(-6, 0, -2), Vector3(3, 0, 9),
		Vector3(-4, 0, 8), Vector3(8, 0, 5), Vector3(-8, 0, 3),
		Vector3(-2, 0, -8)])
	_add(out, "farmer", "farmer", [
		Vector3(-20, 0, -85), Vector3(15, 0, -90),
		Vector3(75, 0, 60), Vector3(90, 0, 70)])
	_add(out, "child", "child", [
		Vector3(-10, 0, 25), Vector3(10, 0, 25), Vector3(-30, 0, 6)])
	_add(out, "warden", "warden", [Vector3(2.5, 0, -51), Vector3(-2.5, 0, 51)])
	_add(out, "drover", "drover", [
		Vector3(-24, 0, 31), Vector3(-20, 0, 34), Vector3(-28, 0, 28)])
	_add(out, "granary", "granary hand", [Vector3(32, 0, 0), Vector3(32, 0, 8)])
	_add(out, "brewery", "brewery hand", [Vector3(18, 0, 31.5)])
	_add(out, "chapel", "chapel-goer", [Vector3(14, 0, -28)])
	_add(out, "smithy", "smithy's apprentice", [Vector3(-5, 0, -26)])
	# The Red Vigil rider: waters his horse at the north gate, then rides.
	out.append({
		"id": "vigil-rider", "name": "Vigil rider", "role": "Red Vigil, passing through",
		"voice": "Terse. The Vigil works the rim roads; culling is holy work.",
		"pos": Vector3(3, 0, -48), "yaw": PI,
		"tunic": Color(0.45, 0.12, 0.12), "warm": false, "uses_name": false,
		"barks": "vigil", "topics": [],
		"departs_after": 75.0, "leave_target": Vector3(0, 0, -54),
	})
	return out


static func _add(out: Array, bark_role: String, role: String, spots: Array) -> void:
	var tunics := [Color(0.52, 0.42, 0.28), Color(0.42, 0.36, 0.26),
		Color(0.48, 0.32, 0.22), Color(0.38, 0.42, 0.30), Color(0.55, 0.48, 0.34)]
	var i := 0
	for p in spots:
		i += 1
		out.append({
			"id": "%s-%d" % [bark_role, i],
			"name": role.capitalize(), "role": role,
			"voice": "",
			"pos": p, "yaw": randf() * TAU,
			"tunic": tunics[i % tunics.size()],
			"warm": true, "uses_name": false,
			"barks": bark_role, "topics": [],
		})


static func all() -> Array:
	var out: Array = []
	out.append_array(named())
	out.append_array(crowd())
	return out
