extends Control
## 节点式河谷地图：画出地点、连线、当前位置和光标所指的目的地。

const MARGIN := 60.0
const NODE_RADIUS := 14.0
const LINK_COLOR := Color(0.55, 0.5, 0.42)
const NODE_COLOR := Color(0.85, 0.8, 0.68)
const CURRENT_COLOR := Color(0.95, 0.6, 0.25)
const TARGET_COLOR := Color(0.45, 0.75, 0.9)

var target_id := "":
	set(value):
		target_id = value
		queue_redraw()


func _ready() -> void:
	GameState.changed.connect(queue_redraw)
	resized.connect(queue_redraw)


func _draw() -> void:
	for location in Data.locations.values():
		for link in location["links"]:
			# 每条连线只画一次。
			if location["id"] < link:
				var highlighted: bool = (
					target_id != ""
					and [location["id"], link].has(target_id)
					and [location["id"], link].has(GameState.location_id)
				)
				draw_line(
					_point(location),
					_point(Data.locations[link]),
					TARGET_COLOR if highlighted else LINK_COLOR,
					4.0 if highlighted else 2.0
				)
	var font := get_theme_default_font()
	for location in Data.locations.values():
		var point := _point(location)
		var color := NODE_COLOR
		if location["id"] == GameState.location_id:
			color = CURRENT_COLOR
		elif location["id"] == target_id:
			color = TARGET_COLOR
		draw_circle(point, NODE_RADIUS, color)
		draw_string(
			font,
			point + Vector2(-80, NODE_RADIUS + 22),
			location["name"],
			HORIZONTAL_ALIGNMENT_CENTER,
			160
		)


func _point(location: Dictionary) -> Vector2:
	var area := size - Vector2(MARGIN, MARGIN) * 2
	return Vector2(MARGIN, MARGIN) + Vector2(location["pos"][0], location["pos"][1]) * area
