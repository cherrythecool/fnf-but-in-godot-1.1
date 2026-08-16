extends AnimationPlayer


var active = ""
var value


func send_signal(signal, v = null):
	active = signal
	value = v
	emit_signal("finished")
