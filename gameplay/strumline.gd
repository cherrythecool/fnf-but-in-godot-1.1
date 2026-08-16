extends Node2D


var SignalBus
var Conductor

const DIRECTIONS = ["left", "down", "up", "right"]
const HIT_WINDOW = 0.18

export var is_opponent = true
export var autoplay = true

var note_scene

var strums
var inputs = []
var local_inputs = []

var chart = {}
var scroll_speed = 1.0

var notes = []
var note_nodes = []
var notes_in_range = []
var note_index = 0


func _enter_tree():
	SignalBus = get_tree().get_current_scene().get_node("SignalBus")
	SignalBus.connect("finished", self, "_on_signal_emit")
	
	Conductor = get_tree().get_current_scene().get_node("Conductor")


func _ready():
	set_process(true)
	note_scene = load("res://gameplay/note.scn")
	
	strums = get_children()

	inputs.resize(strums.size())
	local_inputs.resize(strums.size())


func _process(delta):
	while note_index < notes.size():
		var note = notes[note_index]
		if Conductor.time < note[0] - 1.0:
			break
		
		var node = note_scene.instance()
		node.Conductor = Conductor
		node.column = note[1]
		node.direction = DIRECTIONS[node.column]
		node.time = note[0]
		node.scroll_speed = scroll_speed
		node.set_pos(strums[node.column].get_pos())
		node.set_scale(strums[node.column].get_scale())
		
		add_child(node)
		note_nodes.push_back(node)
		note_index += 1

	notes_in_range.clear()

	var i = 0
	while i < note_nodes.size():
		var node = note_nodes[i]
		
		if Conductor.time > node.time + HIT_WINDOW and not autoplay:
			SignalBus.send_signal("player_note_miss", node)
			node.hide()
			node.queue_free()
			note_nodes.remove(i)
			continue
		
		if Conductor.time < node.time - HIT_WINDOW:
			i += 1
			continue
		
		if autoplay and Conductor.time > node.time:
			SignalBus.send_signal("opponent_note_hit", node)
			strums[node.column].play_anim("confirm")
			node.hide()
			node.queue_free()
			note_nodes.remove(i)
			continue
		
		notes_in_range.push_back(node)
		i += 1

	if not autoplay:
		player_input()
	else:
		for strum in strums:
			if not strum.anim_player.is_playing():
				strum.play_anim("static")


func _notes_sort(a, b):
	return a[0] < b[0]


func _on_signal_emit():
	var cur = SignalBus.active
	if cur != "chart_loaded":
		return
	
	chart = SignalBus.value

	var data = chart["song"]
	scroll_speed = float(data["speed"])

	for section in data["notes"]:
		if not "sectionNotes" in section:
			continue

		for note in section["sectionNotes"]:
			if note[1] < 4 and is_opponent:
				continue
			if note[1] > 3 and not is_opponent:
				continue
			if note[1] < 0:
				continue

			notes.push_back([
				float(note[0]) / 1000.0,
				int(note[1]) % 4,
				float(note[2]),
			])
	
	notes.sort_custom(self, "_notes_sort")


func player_input():
	for i in range(strums.size()):
		var is_pressed = Input.is_action_pressed("input_" + str(i))
		
		if is_pressed and not inputs[i]:
			strums[i].play_anim("press")
		elif not is_pressed:
			strums[i].play_anim("static")
		
		local_inputs[i] = is_pressed and not inputs[i]
		inputs[i] = is_pressed
	
	for note in notes_in_range:
		if not local_inputs[note.column]:
			continue
		
		local_inputs[note.column] = false
		SignalBus.send_signal("player_note_hit", note)
		strums[note.column].play_anim("confirm")
		note.hide()
		note.queue_free()
		note_nodes.erase(note)
