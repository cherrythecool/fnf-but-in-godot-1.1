extends AnimatedSprite


export var direction = "left"

var Conductor

var time = 0.0
var column = 0
var scroll_speed = 1.0

var anim_player


func _ready():
	set_process(true)

	anim_player = get_node("AnimationPlayer")
	anim_player.play(direction)
	
	var Global = get_tree().get_root().get_node("Global")
	if not Global.note_materials.has(direction):
		Global.note_materials[direction] = get_material().duplicate()
	
	set_material(Global.note_materials[direction])
	_process(0)


func _process(delta):
	var p = get_pos()
	set_pos(Vector2(p.x, (Conductor.time - time) * (450.0 * scroll_speed)))