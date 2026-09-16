extends CanvasLayer
## The board's own input: back out, and scroll the list.
##
## Boards is a static class — it has no node of its own to receive input,
## so the CanvasLayer it builds carries this.

## Rows per second at full stick.
const SCROLL_RATE := 620.0

## Set by Boards after it builds the list.
var scroll: ScrollContainer = null


func _unhandled_input(event: InputEvent) -> void:
	if not event.is_action_pressed("ui_cancel"):
		return
	# Only the panel on top acts, so B closes the board and leaves the
	# conversation that opened it standing.
	if UI.top_modal() != self:
		return
	get_viewport().set_input_as_handled()
	Boards._close_ui()


func _process(delta: float) -> void:
	# The board is longer than the screen and read-only, so the only
	# focusable thing on it is the way out — which left a pad able to
	# read the first five contracts and nothing below them. Up and down
	# scroll the list instead of moving a highlight that has nowhere to
	# go.
	#
	# If rows ever become selectable (taking a contract off the board
	# rather than out of a conversation), this goes away: focus
	# navigation with follow_focus does the same job properly.
	if scroll == null or not is_instance_valid(scroll):
		return
	if UI.top_modal() != self:
		return
	var v := Input.get_axis("ui_up", "ui_down")
	if absf(v) < 0.01:
		return
	var reach := maxf(0.0, scroll.get_v_scroll_bar().max_value - scroll.size.y)
	scroll.scroll_vertical = int(clampf(
		float(scroll.scroll_vertical) + v * SCROLL_RATE * delta, 0.0, reach))
