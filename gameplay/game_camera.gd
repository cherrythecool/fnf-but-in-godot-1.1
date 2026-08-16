extends Camera2D


var SignalBus
var Conductor

var targets = []
var sections = []
var sections_index = 0


func _enter_tree():
	SignalBus = get_tree().get_current_scene().get_node("SignalBus")
	SignalBus.connect("finished", self, "_on_signal_emit")


func _ready():
	set_process(true)
	Conductor = get_tree().get_current_scene().get_node("Conductor")
	targets = get_tree().get_current_scene().get_node("CameraTargets").get_children()
	
	set_follow_smoothing(false)
	update_cam_target()
	force_update_scroll()
	set_follow_smoothing(true)


func _process(delta):
	var s = get_zoom()
	s = Vector2(lerp(s.x, 1.0, min(delta * 6.0, 1.0)), lerp(s.y, 1.0, min(delta * 6.0, 1.0)))
	set_zoom(s)
	
	while sections_index < sections.size():
		if Conductor.beat_i > sections[sections_index][0]:
			sections_index += 1
		else:
			break
	
	update_cam_target()


func _on_signal_emit():
	if SignalBus.active == "chart_loaded":
		var chart = SignalBus.value["song"]
		var beat = 0
		
		for section in chart["notes"]:
			sections.push_back([
				beat,
				section["mustHitSection"]
			])
			
			beat += 4

	if SignalBus.active == "beat_hit":
		if SignalBus.value % 4 == 0:
			set_zoom(get_zoom() - Vector2(0.015, 0.015))



func update_cam_target():
	if sections_index > sections.size() - 1:
		return
	
	var section = sections[sections_index]
	if section[1]:
		set_pos(targets[0].get_pos())
	else:
		set_pos(targets[1].get_pos())
