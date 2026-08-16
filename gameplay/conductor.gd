extends Node


var SignalBus

var tracks = []

var bpm = 0.0

var raw_time = 0.0
var time = 0.0
var beat = 0.0
var beat_i = 0

var last_audio_time = 0.0


func _enter_tree():
	SignalBus = get_tree().get_current_scene().get_node("SignalBus")
	SignalBus.connect("finished", self, "_on_signal_emit")


func _ready():
	set_process(true)
	tracks = get_node("Tracks").get_children()
	
	var timer = get_node("Timer")
	timer.start()
	yield(timer, "timeout")
	
	for track in tracks:
		track.play()


func _process(delta):
	if not tracks[0].is_playing():
		return
	
	var last_beat = beat_i
	var audio_time = tracks[0].get_pos()
	
	if last_audio_time != audio_time:
		last_audio_time = audio_time
		raw_time = audio_time
	else:
		raw_time += delta
	
	time = raw_time - ((25.0 + 10.0) / 1000.0)
	beat = time * (bpm / 60.0)
	beat_i = int(beat)
	
	if beat_i > last_beat:
		SignalBus.send_signal("beat_hit", beat_i)


func _on_signal_emit():
	var cur = SignalBus.active
	if cur == "chart_loaded":
		update_from_chart(SignalBus.value)


func update_from_chart(chart):
	var data = chart["song"]
	bpm = data["bpm"]