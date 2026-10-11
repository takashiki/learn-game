extends Control
## 主界面：左边地图，右边是当前地点和可选行动；手记是盖在上面的一层。
## 所有行动都是按钮，靠焦点移动来选择，所以手柄和键盘通用。

const MapView := preload("res://scripts/map_view.gd")
const PANEL_WIDTH := 440
const SCROLL_STEP := 60

var _map: Control
var _status: Label
var _title: Label
var _desc: Label
var _actions: VBoxContainer
var _message: Label
var _journal: PanelContainer
var _journal_scroll: ScrollContainer
var _journal_text: RichTextLabel


func _ready() -> void:
	_build_ui()
	GameState.changed.connect(_refresh)
	_refresh()


func _input(event: InputEvent) -> void:
	if event.is_action_pressed("journal"):
		_toggle_journal()
		get_viewport().set_input_as_handled()
	elif _journal.visible:
		# 手记打开时，方向键只用来滚动，其余输入都吞掉。
		if event.is_action_pressed("ui_cancel"):
			_toggle_journal()
		elif event.is_action_pressed("ui_down", true):
			_journal_scroll.scroll_vertical += SCROLL_STEP
		elif event.is_action_pressed("ui_up", true):
			_journal_scroll.scroll_vertical -= SCROLL_STEP
		if not event is InputEventMouse:
			get_viewport().set_input_as_handled()


func _build_ui() -> void:
	var background := ColorRect.new()
	background.color = Color(0.16, 0.15, 0.13)
	background.set_anchors_preset(Control.PRESET_FULL_RECT)
	add_child(background)

	var layout := HBoxContainer.new()
	layout.set_anchors_preset(Control.PRESET_FULL_RECT)
	add_child(layout)

	_map = MapView.new()
	_map.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	layout.add_child(_map)

	var margin := MarginContainer.new()
	margin.custom_minimum_size.x = PANEL_WIDTH
	for side in ["left", "right", "top", "bottom"]:
		margin.add_theme_constant_override("margin_" + side, 24)
	layout.add_child(margin)

	var panel := VBoxContainer.new()
	panel.add_theme_constant_override("separation", 12)
	margin.add_child(panel)

	_status = Label.new()
	panel.add_child(_status)
	_title = Label.new()
	_title.add_theme_font_size_override("font_size", 28)
	panel.add_child(_title)
	_desc = _wrapped_label()
	panel.add_child(_desc)
	_actions = VBoxContainer.new()
	panel.add_child(_actions)
	_message = _wrapped_label()
	_message.size_flags_vertical = Control.SIZE_EXPAND_FILL
	panel.add_child(_message)
	var hint := Label.new()
	hint.text = "方向键/摇杆 选择　A/回车 确认　Y/J 手记"
	hint.modulate.a = 0.6
	panel.add_child(hint)

	_journal = PanelContainer.new()
	_journal.set_anchors_preset(Control.PRESET_FULL_RECT)
	_journal.visible = false
	add_child(_journal)
	var journal_margin := MarginContainer.new()
	for side in ["left", "right", "top", "bottom"]:
		journal_margin.add_theme_constant_override("margin_" + side, 48)
	_journal.add_child(journal_margin)
	_journal_scroll = ScrollContainer.new()
	journal_margin.add_child(_journal_scroll)
	_journal_text = RichTextLabel.new()
	_journal_text.bbcode_enabled = true
	_journal_text.fit_content = true
	_journal_text.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_journal_scroll.add_child(_journal_text)


func _wrapped_label() -> Label:
	var label := Label.new()
	label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	return label


func _refresh() -> void:
	var location: Dictionary = Data.locations[GameState.location_id]
	_status.text = "%s季　剩余时间 %d" % [GameState.SEASONS[GameState.season], GameState.time_left]
	_title.text = location["name"]
	_desc.text = location["desc"]
	_map.target_id = ""

	for child in _actions.get_children():
		_actions.remove_child(child)
		child.queue_free()

	if GameState.finished:
		_status.text = "休眠"
		_title.text = "舱门合上"
		_desc.text = "你在这条河谷度过了一年，记下 %d 条观察，得出 %d 项发现。下次醒来时，这里会是另一个时代。" % [
			GameState.observed.size(),
			GameState.discovered.size(),
		]
		_add_action("翻看手记", _toggle_journal)
	elif GameState.time_left <= 0:
		_add_action("天色已晚，回着陆舱过完这一季", _end_season)
	else:
		for observation in GameState.available_observations():
			_add_action("观察：" + observation["title"], _observe.bind(observation))
		for link in location["links"]:
			var button := _add_action("前往 " + Data.locations[link]["name"], _travel.bind(link))
			button.focus_entered.connect(func() -> void: _map.target_id = link)
			button.focus_exited.connect(func() -> void: _map.target_id = "")
		if GameState.at_base():
			_add_action("整理笔记", _compile_notes)
			_add_action("结束这一季", _end_season)

	if not _journal.visible and _actions.get_child_count() > 0:
		_actions.get_child(0).grab_focus()


func _add_action(text: String, callback: Callable) -> Button:
	var button := Button.new()
	button.text = text
	button.alignment = HORIZONTAL_ALIGNMENT_LEFT
	button.pressed.connect(callback)
	_actions.add_child(button)
	return button


func _travel(id: String) -> void:
	_message.text = ""
	GameState.travel_to(id)


func _observe(observation: Dictionary) -> void:
	_message.text = observation["text"]
	GameState.observe(observation["id"])


func _compile_notes() -> void:
	_show_discoveries(GameState.compile_notes(), "笔记里还拼不出新的结论。")


func _end_season() -> void:
	var fresh := GameState.compile_notes()
	GameState.end_season()
	_show_discoveries(fresh, "")


func _show_discoveries(fresh: Array, fallback: String) -> void:
	if fresh.is_empty():
		_message.text = fallback
		return
	var lines: Array[String] = []
	for discovery in fresh:
		lines.append("【新发现】%s\n%s" % [discovery["title"], discovery["text"]])
	_message.text = "\n\n".join(lines)


func _toggle_journal() -> void:
	_journal.visible = not _journal.visible
	if _journal.visible:
		_journal_text.text = _journal_bbcode()
		_journal_scroll.scroll_vertical = 0
		var focused := get_viewport().gui_get_focus_owner()
		if focused:
			focused.release_focus()
	elif _actions.get_child_count() > 0:
		_actions.get_child(0).grab_focus()


func _journal_bbcode() -> String:
	var text := "[font_size=28]手记[/font_size]\n\n[b]发现[/b]\n"
	if GameState.discovered.is_empty():
		text += "（还没有）\n"
	for discovery in Data.discoveries:
		if discovery["id"] in GameState.discovered:
			text += "\n[b]%s[/b]\n%s\n[i]现实原型：%s[/i]\n" % [
				discovery["title"],
				discovery["text"],
				discovery["real_basis"],
			]

	text += "\n[b]物种[/b]\n"
	var any_species := false
	for entry in Data.species.values():
		var notes: Array[String] = []
		for observation_id in GameState.observed:
			var observation: Dictionary = Data.observations[observation_id]
			if observation.get("species", "") == entry["id"]:
				notes.append("　· %s：%s" % [observation["title"], observation["text"]])
		if notes.is_empty():
			continue
		any_species = true
		text += "\n[b]%s[/b]　%s\n%s\n[i]现实原型：%s[/i]\n" % [
			entry["name"],
			entry["summary"],
			"\n".join(notes),
			entry["real_basis"],
		]
	if not any_species:
		text += "（还没有）\n"

	text += "\n[b]其他见闻[/b]\n"
	for observation_id in GameState.observed:
		var observation: Dictionary = Data.observations[observation_id]
		if not observation.has("species"):
			text += "　· %s：%s\n" % [observation["title"], observation["text"]]
	return text
