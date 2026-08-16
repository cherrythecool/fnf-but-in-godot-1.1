extends Node


var SignalBus

export(String, DIR) var song_folder = "res://"
export var chart_name = "hard"

var chart = {}


func _ready():
	if song_folder[song_folder.length() - 1] != "/":
		song_folder = song_folder + "/"

	print("loading chart at path " + song_folder + chart_name + ".json")

	var file = File.new()
	var err = file.open(song_folder + chart_name + ".json", File.READ)
	if err != OK:
		print("failed to open chart json: " + str(err))
		return
	
	var json_err = chart.parse_json(file.get_as_text())
	if json_err != OK:
		print("failed to parse chart json: " + str(json_err))
		chart = {}
		return
	
	SignalBus = get_tree().get_current_scene().get_node("SignalBus")
	SignalBus.send_signal("chart_loaded", chart)
