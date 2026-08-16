extends Sprite


export var is_player = false

var SignalBus


func _ready():
	set_process(true)
	
	SignalBus = get_tree().get_current_scene().get_node("SignalBus")
	SignalBus.connect("finished", self, "_on_signal_emit")


func _process(delta):
	var s = get_scale()
	s = Vector2(lerp(s.x, 1.0, min(delta * 9.0, 1.0)), lerp(s.y, 1.0, min(delta * 9.0, 1.0)))
	set_scale(s)


func _on_signal_emit():
	if SignalBus.active == "beat_hit":
		set_scale(Vector2(1.2, 1.2))
	
	if SignalBus.active == "player_note_hit" and is_player:
		set_frame(0)
	
	if SignalBus.active == "player_note_miss" and is_player:
		set_frame(1)