tool
extends Node2D


export(String, DIR) var folder = "res://"

export var symbol = ""
export var frame = 0

var spritemap = {}
var symbols = {}

var stage_symbol = ""
var stage_transform = Matrix32()

var fps = 10.0
var optim

var internal_folder

var last_symbol
var last_frame

var items = []
var items_index = 0


func _ready():
	set_process(true)
	parse()


func _process(delta):
	if last_symbol != symbol:
		last_symbol = symbol
		update()
	
	if last_frame != frame:
		last_frame = frame
		update()


func _draw():
	var use_stage = false
	var target_symbol = symbol
	if not symbols.has(target_symbol):
		target_symbol = stage_symbol
		use_stage = true
	
	for item in items:
		VisualServer.canvas_item_clear(item)
	
	items_index = 0
	
	if not symbols.has(target_symbol):
		VisualServer.canvas_item_clear(get_canvas_item())
		return
	
	var transform
	if use_stage:
		transform = stage_transform
	else:
		transform = Matrix32(Vector2(1, 0), Vector2(0, 1), Vector2(0, 0))
	
	var item = get_canvas_item()
	VisualServer.canvas_item_clear(get_canvas_item())
	draw_symbol(symbols[target_symbol], frame, transform, item)


func get_frame_after(element, amount):
	var symbol = symbols[element["key"]]
	if element["loop_mode"] == key("loop", "LP"):
		return int(max(element["first_frame"] + amount, 0)) % int(symbol["length"])
	elif element["loop_mode"] == key("playonce", "PO"):
		return clamp(element["first_frame"] + amount, 0, symbol["length"] - 1)
	
	print(element["key"])
	return element["first_frame"]


func draw_symbol(symbol, frame, transform, item):
	for i in range(symbol["layers"].size() - 1, -1, -1):
		var layer = symbol["layers"][i]
		if frame > layer["length"] - 1:
			continue
		
		for layer_frame in layer["frames"]:
			if frame < layer_frame["index"]:
				break
			if frame > layer_frame["index"] + layer_frame["duration"] - 1:
				continue
			
			for element in layer_frame["elements"]:
				if element["type"] == "SI":
					draw_symbol(symbols[element["key"]], get_frame_after(element, frame), transform * element["transform"], item)
				elif element["type"] == "ASI":
					var new_item
					items_index += 1
					
					if items_index > items.size() - 1:
						new_item = VisualServer.canvas_item_create()
						items.push_back(new_item)
					else:
						new_item = items[items_index]
					
					VisualServer.canvas_item_set_parent(new_item, item)
					
					var tex = spritemap[element["key"]]
					var sprite_transform = Matrix32(Vector2(1, 0), Vector2(0, 1), Vector2(0, 0))
					if tex.get_meta("rotated") == true:
						sprite_transform = sprite_transform.translated(Vector2(0, tex.get_width()))
						sprite_transform = sprite_transform.rotated(deg2rad(90.0))
					
					VisualServer.canvas_item_set_transform(new_item, element["transform"] * transform * sprite_transform)
					tex.draw(new_item, Vector2(0, 0))


func parse():
	spritemap = {}

	internal_folder = folder
	if internal_folder[internal_folder.length() - 1] != "/":
		internal_folder += "/"
	
	print("loading atlas at " + internal_folder)
	
	var dir = Directory.new()
	var open_err = dir.open(internal_folder)
	if open_err != OK:
		print("failed to open dir " + internal_folder + " with err " + str(open_err))
		return
	
	dir.list_dir_begin()
	
	var found_anim = false
	var found_maps = []
	
	var dir_file = dir.get_next()
	while dir_file != "":
		if dir.current_is_dir():
			pass
		else:
			if dir_file == "Animation.json":
				found_anim = true
			elif dir_file.begins_with("spritemap") and dir_file.extension() == "json":
				found_maps.push_back(dir_file)

		dir_file = dir.get_next()
	
	print("found anim: " + str(found_anim) + " found maps: " + str(found_maps))
	if found_maps.empty() or not found_anim:
		print("missing critical shit, canceling lol")
		return
	
	for map in found_maps:
		parse_spritemap(map)
	
	parse_animation()


func parse_spritemap(map):
	print("parsing map " + str(map))
	
	var tex = load(internal_folder + map.replace(".json", ".png"))
	var json = File.new()
	var json_open = json.open(internal_folder + map, File.READ)
	if json_open != OK:
		print("failed to open spritemap json " + map + " with err " + str(json_open))
		return
	
	var map_data = {}
	var parse_err = map_data.parse_json(json.get_as_text())
	json.close()
	if parse_err != OK:
		print("failed to parse spritemap json with err " + str(parse_err))
		return
	
	var sprites = map_data["ATLAS"]["SPRITES"]
	for sprite in sprites:
		var data = sprite["SPRITE"]
		var atlas_tex = AtlasTexture.new()
		atlas_tex.atlas = tex
		atlas_tex.set_region(Rect2(data["x"], data["y"], data["w"], data["h"]))
		
		if data.has("rotated"):
			atlas_tex.set_meta("rotated", data["rotated"])
		else:
			atlas_tex.set_meta("rotated", false)
		
		spritemap[data["name"]] = atlas_tex


func key(key_unopt, key_opt):
	if optim:
		return key_opt
	else:
		return key_unopt


func parse_animation():
	print("parsing animation.json")
	
	var json = File.new()
	var json_open = json.open(internal_folder + "Animation.json", File.READ)
	if json_open != OK:
		print("failed to open anim json with err " + str(json_open))
		return
	
	var data = {}
	var parse_err = data.parse_json(json.get_as_text())
	json.close()
	if parse_err != OK:
		print("failed to parse animation json with err " + str(parse_err))
		return
	
	optim = data.has("AN")
	if data.has(key("metadata", "MD")):
		fps = data[key("metadata", "MD")][key("framerate", "FRT")]
	
	var anim = data[key("ANIMATION", "AN")]
	
	stage_transform = Matrix32()
	if anim.has(key("StageInstance", "STI")):
		if anim[key("StageInstance", "STI")].has(key("SYMBOL_Instance", "SI")):
			if anim[key("StageInstance", "STI")][key("SYMBOL_Instance", "SI")].has(key("Matrix", "MX")):
				stage_transform = parse_matrix(anim[key("StageInstance", "STI")][key("SYMBOL_Instance", "SI")][key("Matrix", "MX")])
			elif anim[key("StageInstance", "STI")][key("SYMBOL_Instance", "SI")].has(key("Matrix3D", "M3D")):
				stage_transform = parse_matrix(anim[key("StageInstance", "STI")][key("SYMBOL_Instance", "SI")][key("Matrix3D", "M3D")])
	
	stage_symbol = anim[key("SYMBOL_name", "SN")]
	parse_symbol(anim)
	
	if data.has(key("SYMBOL_DICTIONARY", "SD")):
		var symbols = data[key("SYMBOL_DICTIONARY", "SD")][key("Symbols", "S")]
		for symbol in symbols:
			parse_symbol(symbol)


func parse_symbol(data):
	var key = data[key("SYMBOL_name", "SN")]
	var symbol = {
		"length": 0,
		"layers": [],
	}
	
	var layers
	if data.has(key("TIMELINE", "TL")):
		layers = data[key("TIMELINE", "TL")][key("LAYERS", "L")]
	else:
		layers = data[key("LAYERS", "L")]
	
	for layer in layers:
		var parsed_layer = parse_layer(layer)
		if symbol["length"] < parsed_layer["length"]:
			symbol["length"] = parsed_layer["length"]
		
		symbol["layers"].push_back(parsed_layer)
	
	symbols[key] = symbol
	return symbol


func parse_layer(data):
	var layer = {
		"name": "",
		"frames": [],
		"length": 0,
	}
	
	layer["name"] = data[key("Layer_name", "LN")]
	
	if data.has(key("Frames", "FR")):
		var frames = data[key("Frames", "FR")]
		for frame in frames:
			var parsed_frame = parse_frame(frame)
			if layer["length"] < parsed_frame["index"] + parsed_frame["duration"]:
				layer["length"] = parsed_frame["index"] + parsed_frame["duration"]
			
			layer.frames.push_back(parsed_frame)
	
	return layer


func parse_frame(data):
	var frame = {
		"index": 0,
		"duration": 0,
		"elements": [],
	}
	
	frame["index"] = data[key("index", "I")]
	frame["duration"] = data[key("duration", "DU")]
	
	if data.has(key("elements", "E")):
		var elements = data[key("elements", "E")]
		for element in elements:
			if element == null:
				continue
			
			if element.has(key("SYMBOL_Instance", "SI")):
				frame["elements"].push_back(parse_symbol_instance(element[key("SYMBOL_Instance", "SI")]))
			elif element.has(key("ATLAS_SPRITE_Instance", "ASI")):
				frame["elements"].push_back(parse_atlas_sprite_instance(element[key("ATLAS_SPRITE_Instance", "ASI")]))
	
	return frame


func parse_atlas_sprite_instance(data):
	var element = {
		"type": "ASI",
		"key": "",
		"transform": Matrix32(Vector2(1, 0), Vector2(0, 1), Vector2(0, 0)),
	}
	
	element["key"] = data[key("name", "N")]
	
	if data.has(key("Matrix", "MX")):
		element["transform"] = parse_matrix(data[key("Matrix", "MX")])
	elif data.has(key("Matrix3D", "M3D")):
		element["transform"] = parse_matrix(data[key("Matrix3D", "M3D")])
	
	return element


func parse_symbol_instance(data):
	var element = {
		"type": "SI",
		"key": "",
		"first_frame": 0,
		
		# other options: playonce, PO, singleframe, SF
		"loop_mode": key("loop", "LP"),
		"transform": Matrix32(Vector2(1, 0), Vector2(0, 1), Vector2(0, 0)),
	}
	
	element["key"] = data[key("SYMBOL_name", "SN")]
	
	if data.has(key("firstFrame", "FF")):
		element["first_frame"] = data[key("firstFrame", "FF")]
	
	if data.has(key("Matrix", "MX")):
		element["transform"] = parse_matrix(data[key("Matrix", "MX")])
	elif data.has(key("Matrix3D", "M3D")):
		element["transform"] = parse_matrix(data[key("Matrix3D", "M3D")])
	
	if data.has(key("loop", "LP")):
		element["loop_mode"] = data[key("loop", "LP")]
	
	return element


func parse_matrix(matrix):
	if typeof(matrix) == TYPE_DICTIONARY:
		return Matrix32(Vector2(matrix["m00"], matrix["m01"]), Vector2(matrix["m10"], matrix["m11"]), Vector2(matrix["m30"], matrix["m31"]))
	elif typeof(matrix) == TYPE_ARRAY:
		if matrix.size() >= 6 and matrix.size() < 14:
			return Matrix32(Vector2(matrix[0], matrix[1]), Vector2(matrix[2], matrix[3]), Vector2(matrix[4], matrix[5]))
		elif matrix.size() >= 14:
			return Matrix32(Vector2(matrix[0], matrix[1]), Vector2(matrix[4], matrix[5]), Vector2(matrix[12], matrix[13]))

	return Matrix32(Vector2(1, 0), Vector2(0, 1), Vector2(0, 0))
