extends Node
## 从 data/ 下的 JSON 读入全部游戏内容。新增内容只改 JSON，不改代码。

var locations: Dictionary = {}
var species: Dictionary = {}
var discoveries: Array = []
var npcs: Dictionary = {}
## 观察 id -> 观察条目，方便图鉴按 id 查找。对话里听来的见闻也登记在这里。
var observations: Dictionary = {}


func _ready() -> void:
	for location in _load_json("res://data/locations.json"):
		locations[location["id"]] = location
		for observation in location["observations"]:
			observations[observation["id"]] = observation
	for entry in _load_json("res://data/species.json"):
		species[entry["id"]] = entry
	discoveries = _load_json("res://data/discoveries.json")
	for npc in _load_json("res://data/npcs.json"):
		npcs[npc["id"]] = npc
		for dialogue in npc["dialogues"]:
			if dialogue.has("teaches"):
				observations[dialogue["teaches"]["id"]] = dialogue["teaches"]
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
	# 对话的前置条件可以是观察、发现或另一段对话。
	var known_ids: Array = observations.keys()
	for discovery in discoveries:
		known_ids.append(discovery["id"])
	for npc in npcs.values():
		for dialogue in npc["dialogues"]:
			known_ids.append(dialogue["id"])
	for npc in npcs.values():
		if npc["schedule"].size() != 4:
			push_error("人物 %s 的 schedule 必须正好有四季" % npc["id"])
		for place in npc["schedule"]:
			if place != null and not locations.has(place):
				push_error("人物 %s 出现在不存在的地点 %s" % [npc["id"], place])
		for dialogue in npc["dialogues"]:
			for required in dialogue.get("requires", []):
				if not required in known_ids:
					push_error("对话 %s 需要不存在的条件 %s" % [dialogue["id"], required])
