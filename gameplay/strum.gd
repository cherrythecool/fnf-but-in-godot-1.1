extends AnimatedSprite


export var direction = "left"

var anim_player


func _ready():
	anim_player = get_node("AnimationPlayer")
	play_anim("static")
	set_material(get_material().duplicate())


func play_anim(anim, force = false):
	anim_player.play(direction + "_" + anim)
	
	if force:
		anim_player.seek(0)