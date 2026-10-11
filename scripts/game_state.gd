extends Node
## 一局游戏的全部进度。

signal changed

const SEASONS: Array[String] = ["春", "夏", "秋", "冬"]
const TIME_PER_SEASON := 8
const BASE_ID := "base"

var season := 0
var time_left := TIME_PER_SEASON
var location_id := BASE_ID
var observed: Array[String] = []
var discovered: Array[String] = []
var finished := false


func at_base() -> bool:
	return location_id == BASE_ID


func travel_to(id: String) -> void:
	location_id = id
	time_left -= 1
	changed.emit()


## 当前地点、当前季节里还没记录过的观察。
func available_observations() -> Array:
	var result: Array = []
	for observation in Data.locations[location_id]["observations"]:
		# JSON 里的数字读进来是 float，所以用 float 比较。
		if float(season) in observation["seasons"] and not observation["id"] in observed:
			result.append(observation)
	return result


func observe(observation_id: String) -> void:
	observed.append(observation_id)
	time_left -= 1
	changed.emit()


## 把已有的观察拼成发现，返回这次新得到的发现。
func compile_notes() -> Array:
	var fresh: Array = []
	for discovery in Data.discoveries:
		if discovery["id"] in discovered:
			continue
		var complete := true
		for required in discovery["requires"]:
			if not required in observed:
				complete = false
				break
		if complete:
			discovered.append(discovery["id"])
			fresh.append(discovery)
	if not fresh.is_empty():
		changed.emit()
	return fresh


## 回到着陆舱并进入下一季；冬天结束后进入休眠。
func end_season() -> void:
	location_id = BASE_ID
	season += 1
	time_left = TIME_PER_SEASON
	if season >= SEASONS.size():
		season = SEASONS.size() - 1
		finished = true
	changed.emit()
