extends CanvasLayer


var SignalBus
var Conductor

var root


func _ready():
	set_process(true)

	SignalBus = get_tree().get_current_scene().get_node("SignalBus")
	SignalBus.connect("finished", self, "_on_signal_emit")

	Conductor = get_tree().get_current_scene().get_node("Conductor")
	
	root = get_node("Root")


func _process(delta):
	var s = root.get_scale()
	s = Vector2(lerp(s.x, 1.0, min(delta * 6.0, 1.0)), lerp(s.y, 1.0, min(delta * 6.0, 1.0)))
	root.set_scale(s)


func _on_signal_emit():
	if SignalBus.active == "beat_hit":
		if SignalBus.value % 4 == 0:
			root.set_scale(root.get_scale() + Vector2(0.03, 0.03))