class_name RoutineRules
extends RefCounted
## GDScript mirror of sim/Marrowmark.Sim/Town/Routine.cs.
##
## L88: sim/ is authoritative and this mirrors it. The C# is the copy
## that is tested (10 tests) and the copy the server will run.
##
## **A town is alive when it has a life that does not depend on you.**
## Thornfield had a sun crossing the sky and thirty-four people standing
## in the same spots at three in the morning as at noon, which reads as a
## diorama however good the light is.
##
## This is a RULE rather than a scene behaviour for the same reason the
## clock is (L89): the server decides where people are. Two players
## walking into the inn at dusk have to find the same innkeeper there.
## The scene's only job is knowing where "the inn" is on the ground.


## Does a posting cover this hour? Wraps past midnight when from > to,
## which is the normal case for anybody who sleeps — and the case that
## breaks a naive from <= h < to comparison.
static func covers(posting: Dictionary, hour: float) -> bool:
	var from := float(posting.get("from", 0.0))
	var to := float(posting.get("to", 24.0))
	if from <= to:
		return hour >= from and hour < to
	return hour >= from or hour < to


## Where this person should be at this hour.
static func place_for(routine: Dictionary, hour: float) -> String:
	if routine.is_empty():
		return "home"
	var h := _wrap(hour)
	for p in routine.get("postings", []):
		if covers(p, h):
			return String(p.get("place", "home"))
	return String(routine.get("fallback", "home"))


## An hour past the end of the dial wraps rather than falling through —
## a clock handing over 24.5 instead of 0.5 must not send everybody home.
static func _wrap(hour: float) -> float:
	var h: float = fmod(hour, 24.0)
	return h + 24.0 if h < 0.0 else h


## Is the town awake at all? For the things that are about the town
## rather than about one person.
static func waking(hour: float) -> bool:
	var h := _wrap(hour)
	return h >= 6.0 and h < 22.0
