extends CanvasLayer


var SignalBus
var Conductor

var root

var ratings_node
var rating_spr
var numbers_node

var rating_sprites = {}
var combo_sprites = []

var ratings_fade_timer = -1.0

var score = 0
var combo = 0
var misses = 0

var score_label


func _ready():
	set_process(true)

	SignalBus = get_tree().get_current_scene().get_node("SignalBus")
	SignalBus.connect("finished", self, "_on_signal_emit")

	Conductor = get_tree().get_current_scene().get_node("Conductor")
	
	root = get_node("Root")
	
	score_label = root.get_node("ScoreLabel")
	
	ratings_node = root.get_node("Ratings")
	rating_spr = root.get_node("Ratings/Rating")
	numbers_node = root.get_node("Ratings/Numbers")
	
	for i in range(10):
		combo_sprites.push_back(load("res://gameplay/dsides_ratings/num" + str(i) + ".png"))
	
	for rating in ["sick", "good", "bad", "shit"]:
		rating_sprites[rating] = load("res://gameplay/dsides_ratings/" + rating + ".png")
	
	update_score_text()


func _process(delta):
	var s = root.get_scale()
	s = Vector2(lerp(s.x, 1.0, min(delta * 6.0, 1.0)), lerp(s.y, 1.0, min(delta * 6.0, 1.0)))
	root.set_scale(s)
	
	var r_s = ratings_node.get_scale()
	r_s = Vector2(lerp(r_s.x, 1.0, min(delta * 15.0, 1.0)), lerp(r_s.y, 1.0, min(delta * 15.0, 1.0)))
	ratings_node.set_scale(r_s)
	
	ratings_fade_timer -= delta
	if ratings_fade_timer < 0.0:
		ratings_node.set_opacity(1 - min(-ratings_fade_timer * PI, 1.0))


func _on_signal_emit():
	if SignalBus.active == "beat_hit":
		if SignalBus.value % 4 == 0:
			root.set_scale(root.get_scale() + Vector2(0.03, 0.03))
	
	if SignalBus.active == "player_note_miss":
		combo = 0
		score -= 10
		misses += 1

	if SignalBus.active == "player_note_hit":
		combo += 1
		
		var note = SignalBus.value
		var diff = abs(Conductor.time - note.time)
		var rating = "sick"
		
		if diff <= 0.045:
			rating = "sick"
			score += 200
		elif diff <= 0.09:
			rating = "good"
			score += 100
		elif diff <= 0.135:
			rating = "bad"
			score += 10
		else:
			rating = "shit"
			score -= 10
		
		rating_spr.set_texture(rating_sprites[rating])
		
		ratings_node.set_opacity(1.0)
		ratings_node.set_scale(Vector2(1.1, 1.1))
		ratings_fade_timer = 0.5
		
		var combo_str = str(combo).pad_zeros(3)
		for i in range(combo_str.length()):
			var c = combo_str[i]
			
			if i < numbers_node.get_child_count():
				numbers_node.get_child(i).set_texture(combo_sprites[int(c)])
	
	update_score_text()


func update_score_text():
	score_label.set_text("Score:" + str(score) + " - Misses:" + str(misses))
