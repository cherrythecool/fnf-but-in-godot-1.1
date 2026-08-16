extends Node


var note_materials = {}
var was_pressed_fullscreen = false


func _ready():
	set_process(true)
	VisualServer.set_default_clear_color(Color(0, 0, 0))
	OS.set_window_position((OS.get_screen_size() - OS.get_window_size()) / 2.0)


func _process(delta):
	var fullscreen_pressed = Input.is_action_pressed("toggle_fullscreen")
	
	if was_pressed_fullscreen != fullscreen_pressed:
		was_pressed_fullscreen = fullscreen_pressed
		
		if fullscreen_pressed:
			OS.set_window_fullscreen(not OS.is_window_fullscreen())