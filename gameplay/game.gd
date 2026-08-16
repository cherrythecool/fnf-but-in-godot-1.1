extends Node2D


var SignalBus
var Conductor

var opponent_anims
var opponent_sing_timer = 0.0
var opponent_last_anim = "idle"

var player_anims
var player_strums
var player_sing_timer = 0.0
var player_last_anim = "idle"


func _ready():
	set_process(true)
	
	SignalBus = get_tree().get_current_scene().get_node("SignalBus")
	SignalBus.connect("finished", self, "_on_signal_emit")
	
	Conductor = get_tree().get_current_scene().get_node("Conductor")
	
	player_anims = get_node("Player").get_node("AnimationPlayer")
	opponent_anims = get_node("Opponent").get_node("AnimationPlayer")
	player_strums = get_node("HUD/Root/PlayerStrums")


func _process(delta):
	player_sing_timer += delta / (60.0 / Conductor.bpm)
	if player_sing_timer >= 1.0 and player_last_anim == "sing" and not true in player_strums.inputs:
		player_last_anim = "idle"
		player_anims.play("idle")
	
	opponent_sing_timer += delta / (60.0 / Conductor.bpm)
	if opponent_sing_timer >= 1.0 and opponent_last_anim == "sing":
		opponent_last_anim = "idle"
		opponent_anims.play("idle")


func _on_signal_emit():
	if SignalBus.active == "beat_hit":
		if player_anims != null and player_last_anim == "idle" and not player_anims.is_playing():
			player_last_anim = "idle"
			player_anims.play("idle")
		
		if opponent_anims != null and opponent_last_anim == "idle" and not opponent_anims.is_playing():
			opponent_last_anim = "idle"
			opponent_anims.play("idle")
	
	if SignalBus.active == "player_note_hit":
		if player_anims != null:
			player_last_anim = "sing"
			player_anims.play("sing_" + SignalBus.value.direction)
			player_sing_timer = 0.0
	
	if SignalBus.active == "opponent_note_hit":
		if opponent_anims != null:
			opponent_last_anim = "sing"
			opponent_anims.play("sing_" + SignalBus.value.direction)
			opponent_sing_timer = 0.0