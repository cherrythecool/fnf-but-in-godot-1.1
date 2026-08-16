extends Control

var file_dialog

func _ready():
	file_dialog = get_node("FileDialog")
	file_dialog.set_mode(FileDialog.MODE_OPEN_FILE)
	file_dialog.set_current_dir("res://")
	file_dialog.add_filter("*.xml")


func _on_select_pressed():
	file_dialog.popup_centered()


func _on_file_selected(path):
	var frames = SpriteFrames.new()
	var texture = load(path.replace(".xml", ".png"))
	var xml = XMLParser.new()
	xml.open(path)

	while xml.read() == OK:
		var node_type = xml.get_node_type()
		if node_type != XMLParser.NODE_ELEMENT:
			continue
		
		var node_name = xml.get_node_name()
		if node_name.to_lower() != "subtexture":
			continue
		
		var sprite_name = xml.get_named_attribute_value_safe("name")
		var x = float(xml.get_named_attribute_value_safe("x"))
		var y = float(xml.get_named_attribute_value_safe("y"))
		var w = float(xml.get_named_attribute_value_safe("width"))
		var h = float(xml.get_named_attribute_value_safe("height"))
		
		var rotated = xml.get_named_attribute_value_safe("rotated") == "true"
		
		var source = Rect2(Vector2(x, y), Vector2(w, h))
		
		var frame_x = float(xml.get_named_attribute_value_safe("frameX"))
		var frame_y = float(xml.get_named_attribute_value_safe("frameY"))
		var frame_w = float(xml.get_named_attribute_value_safe("frameWidth"))
		var frame_h = float(xml.get_named_attribute_value_safe("frameHeight"))
		
		frame_w = max(frame_w, w)
		frame_h = max(frame_h, h)
		
		var offset = Rect2(0, 0, 0, 0)
		offset.pos.x = abs(frame_x)
		offset.size.x = frame_w - w
		offset.pos.y = abs(frame_y)
		offset.size.y = frame_h - h
		
		if rotated:
			pass
		else:
			var atlas = AtlasTexture.new()
			atlas.set_atlas(texture)
			atlas.set_region(source)
			atlas.set_margin(offset)
			frames.add_frame(atlas)
	
	frames.take_over_path(path.replace(".xml", ".res"))
	ResourceSaver.save(path.replace(".xml", ".res"), frames, ResourceSaver.FLAG_COMPRESS)
