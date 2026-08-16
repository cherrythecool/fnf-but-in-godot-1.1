extends Label


func _ready():
	set_process(true)
	update()


func _process(delta):
	update()


func update():
	set_text(str(OS.get_frames_per_second()) + " FPS")