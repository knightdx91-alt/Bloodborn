extends Node3D
func _ready() -> void:
	var w := (load("res://main.tscn") as PackedScene).instantiate()
	add_child(w)
	for i in 6: await get_tree().process_frame
	if w._phase_label != null: w._phase_label.visible = false
	w.player.position = Vector3(2, 1, 4)
	w.enemy.position = Vector3(3.4, 1, 2.0)
	w.player.rotation.y = 0.25
	w.enemy.rotation.y = PI - 0.5
	for i in 20: await get_tree().physics_frame
	w.set_physics_process(false)
	await get_tree().process_frame
	w.cam.look_at_from_position(Vector3(2.3, 1.55, 6.1), Vector3(2.6, 1.05, 2.6), Vector3.UP)
	await RenderingServer.frame_post_draw
	await RenderingServer.frame_post_draw
	get_viewport().get_texture().get_image().save_png("/tmp/armour_a.png")

	# L63 made visible: the helm and the arms come off.
	w.player.shed(Armour.Slot.HEAD)
	w.player.shed(Armour.Slot.ARMS)
	await get_tree().process_frame
	await RenderingServer.frame_post_draw
	await RenderingServer.frame_post_draw
	get_viewport().get_texture().get_image().save_png("/tmp/armour_b.png")
	print("after shedding: head=%s arms=%s torso=%s legs=%s" % [
		str(w.player.wearing(Armour.Slot.HEAD)), str(w.player.wearing(Armour.Slot.ARMS)),
		str(w.player.wearing(Armour.Slot.TORSO)), str(w.player.wearing(Armour.Slot.LEGS))])
	get_tree().quit()
