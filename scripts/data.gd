extends Node
## 从 data/ 下的 JSON 读入全部游戏内容。新增内容只改 JSON，不改代码。

var locations: Dictionary = {}
var species: Dictionary = {}
var discoveries: Array = []
## 观察 id -> 观察条目，方便图鉴按 id 查找。
var observations: Dictionary = {}


func _ready() -> void:
	for location in _load_json("res://data/locations.json"):
		locations[location["id"]] = location
		for observation in location["observations"]:
			observations[observation["id"]] = observation
	for entry in _load_json("res://data/species.json"):
		species[entry["id"]] = entry
	discoveries = _load_json("res://data/discoveries.json")
	_validate()


func _load_json(path: String) -> Array:
	var parsed: Variant = JSON.parse_string(FileAccess.get_file_as_string(path))
	if not parsed is Array:
		push_error("无法解析 %s" % path)
		return []
	return parsed


func _validate() -> void:
	for location in locations.values():
		for link in location["links"]:
			if not locations.has(link):
				push_error("地点 %s 连到了不存在的地点 %s" % [location["id"], link])
			elif not location["id"] in locations[link]["links"]:
				push_error("地点 %s -> %s 的连接不是双向的" % [location["id"], link])
		for observation in location["observations"]:
			if observation.has("species") and not species.has(observation["species"]):
				push_error("观察 %s 引用了不存在的物种 %s" % [observation["id"], observation["species"]])
	for discovery in discoveries:
		for required in discovery["requires"]:
			if not observations.has(required):
				push_error("发现 %s 需要不存在的观察 %s" % [discovery["id"], required])
