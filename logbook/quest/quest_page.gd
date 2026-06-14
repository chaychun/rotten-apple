extends BookPage

@onready var _quest_name: Label = $InfoPage/QuestName
@onready var _posted_by: Label = $InfoPage/MetaRow/PostedBy
@onready var _status_chip: Label = $InfoPage/MetaRow/StatusChip
@onready var _rule: ColorRect = $InfoPage/Rule
@onready var _body: RichTextLabel = $InfoPage/Body
@onready var _reward_value: Label = $InfoPage/RewardRow/RewardValue
@onready var _info_page: Control = $InfoPage
@onready var _right_page: Control = $RightPage
@onready var _photo_center: CenterContainer = $RightPage/PhotoCenter
@onready var _photo: TextureRect = $RightPage/PhotoCenter/PhotoFrame/Photo
@onready var _requirements: VBoxContainer = $RightPage/Requirements
@onready var _submit: Button = $RightPage/Submit
@onready var _empty_label: Label = $EmptyLabel

# palette
const _INK := Color(0.29, 0.2, 0.13)
const _INK_SOFT := Color(0.4, 0.3, 0.2)
const _CREAM := Color(0.97, 0.93, 0.86)
const _BORDER := Color(0.547, 0.362, 0.272)
const _DONE := Color(0.34, 0.52, 0.32)
const _MUTED := Color(0.55, 0.45, 0.32)
const _PILL := {
	QuestStatus.ACTIVE: Color(0.36, 0.49, 0.45),
	QuestStatus.MAILED: Color(0.82, 0.55, 0.2),
	QuestStatus.SUBMITTED: Color(0.55, 0.5, 0.35),
	QuestStatus.DONE: Color(0.34, 0.52, 0.32),
	QuestStatus.FAILED: Color(0.7, 0.32, 0.27),
}

# For submitting at stash wiring. Flip this when interact.
var submit_enabled := true

var _ids: Array[String] = []
var _current_id := ""
var _variant_choice: Dictionary = {}  # species -> is_real chosen for submission


func _ready() -> void:
	_submit.pressed.connect(_on_submit)
	Events.quest_accepted.connect(func(_id: String) -> void: _refresh_if_open())
	Events.quest_submitted.connect(func(_id: String) -> void: _refresh_if_open())
	Events.quest_carried.connect(func(_id: String, _r: int) -> void: _refresh_if_open())
	Events.quest_completed.connect(func(_id: String) -> void: _refresh_if_open())
	Events.quest_failed.connect(func(_id: String, _r: int) -> void: _refresh_if_open())
	Events.animal_caught.connect(func(_id: String) -> void: _render_if_open())
	Events.mail_read.connect(func(_m: MailData) -> void: _render_if_open())


func is_empty() -> bool:
	return _ids.is_empty()


func on_show() -> void:
	_refresh_list()


func go_prev() -> void:
	_step(-1)


func go_next() -> void:
	_step(1)


func _refresh_if_open() -> void:
	if visible:
		_refresh_list()


func _render_if_open() -> void:
	if visible:
		_render()


func _step(dir: int) -> void:
	if _ids.is_empty():
		return
	var i := _ids.find(_current_id)
	if i == -1:
		i = 0
	i = (i + dir + _ids.size()) % _ids.size()
	_current_id = _ids[i]
	_render()


# Rebuilds the ordered quest list, keeping the current quest selected if still present.
func _refresh_list() -> void:
	_ids = PlayerState.get_logbook_quests()
	if _ids.is_empty():
		_current_id = ""
		_info_page.visible = false
		_right_page.visible = false
		_empty_label.visible = true
		contents_changed.emit()
		return
	if not _ids.has(_current_id):
		_current_id = _ids[0]
	_info_page.visible = true
	_empty_label.visible = false
	_render()
	contents_changed.emit()


func _render() -> void:
	if _current_id == "":
		return
	var quest: QuestData = QuestRegistry.get_quest(_current_id)
	if quest == null:
		return
	var status := PlayerState.get_quest_status(_current_id)

	_quest_name.text = quest.quest_name
	_posted_by.text = quest.posted_by
	_apply_status_pill(status)
	_reward_value.text = "%d coins" % quest.reward

	var mail: MailData = Mailbox.latest_for_quest(_current_id)
	_body.text = mail.message if mail != null else quest.description

	var photo: Texture2D = mail.photo if mail != null else null
	_photo.texture = photo
	_photo_center.visible = photo != null

	_right_page.visible = true
	_build_requirements(quest, status)
	_update_submit(quest, status)


func _apply_status_pill(status: int) -> void:
	_status_chip.text = _status_label(status)
	var box := StyleBoxFlat.new()
	box.bg_color = _PILL.get(status, _MUTED)
	box.set_corner_radius_all(14)
	box.content_margin_left = 16
	box.content_margin_right = 16
	box.content_margin_top = 6
	box.content_margin_bottom = 6
	_status_chip.add_theme_stylebox_override("normal", box)


func _build_requirements(quest: QuestData, status: int) -> void:
	for child in _requirements.get_children():
		child.queue_free()

	for req: QuestRequirement in quest.requirements:
		var card := PanelContainer.new()
		card.add_theme_stylebox_override("panel", _card_box())
		_requirements.add_child(card)

		var vb := VBoxContainer.new()
		vb.add_theme_constant_override("separation", 8)
		vb.mouse_filter = Control.MOUSE_FILTER_IGNORE
		card.add_child(vb)

		var header := Label.new()
		header.text = "%s  ·  need %d" % [req.species, req.amount]
		header.mouse_filter = Control.MOUSE_FILTER_IGNORE
		header.add_theme_color_override("font_color", _INK)
		header.add_theme_font_size_override("font_size", 26)
		vb.add_child(header)

		var sufficient: Array[bool] = []
		var any_variant := false
		for is_real in [true, false]:
			var v: AnimalData = AnimalRegistry.get_variant(req.species, is_real)
			if v == null or not PlayerState.is_caught(v.id):
				continue  # discovery gate: hide undiscovered variant
			any_variant = true
			var held := PlayerState.get_count(v.id)
			vb.add_child(_variant_row(v.display_name, held, req.amount))
			if held >= req.amount:
				sufficient.append(is_real)

		if not any_variant:
			var none := Label.new()
			none.text = "   none caught yet"
			none.mouse_filter = Control.MOUSE_FILTER_IGNORE
			none.add_theme_color_override("font_color", _MUTED)
			none.add_theme_font_size_override("font_size", 22)
			vb.add_child(none)

		# Resolve the variant to submit for this requirement.
		if sufficient.size() == 1:
			_variant_choice[req.species] = sufficient[0]
		elif sufficient.is_empty():
			_variant_choice.erase(req.species)
		else:
			# Both variants sufficient: player picks. Only offer while submittable.
			if status == QuestStatus.ACTIVE and submit_enabled:
				vb.add_child(_variant_toggles(req))


# TODO: swap name to animal sprite
func _variant_row(display: String, held: int, need: int) -> Control:
	var done := held >= need
	var hb := HBoxContainer.new()
	hb.mouse_filter = Control.MOUSE_FILTER_IGNORE

	var n := Label.new()
	n.text = display
	n.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	n.mouse_filter = Control.MOUSE_FILTER_IGNORE
	n.add_theme_color_override("font_color", _INK_SOFT)
	n.add_theme_font_size_override("font_size", 23)
	hb.add_child(n)

	var count := Label.new()
	count.text = "%s  %d/%d" % ["✓" if done else "•", min(held, need), need]
	count.mouse_filter = Control.MOUSE_FILTER_IGNORE
	count.add_theme_color_override("font_color", _DONE if done else _INK_SOFT)
	count.add_theme_font_size_override("font_size", 23)
	hb.add_child(count)
	return hb


func _variant_toggles(req: QuestRequirement) -> Control:
	var group := ButtonGroup.new()
	var hb := HBoxContainer.new()
	hb.mouse_filter = Control.MOUSE_FILTER_IGNORE
	hb.add_theme_constant_override("separation", 8)
	for is_real in [true, false]:
		var v: AnimalData = AnimalRegistry.get_variant(req.species, is_real)
		if v == null:
			continue
		var tb := Button.new()
		tb.toggle_mode = true
		tb.button_group = group
		tb.text = v.display_name
		tb.focus_mode = Control.FOCUS_NONE
		tb.add_theme_font_size_override("font_size", 22)
		tb.add_theme_color_override("font_color", _INK)
		tb.add_theme_color_override("font_hover_color", _INK)
		tb.add_theme_color_override("font_pressed_color", _CREAM)
		tb.add_theme_stylebox_override("normal", _toggle_box(Color(0.83, 0.75, 0.64)))
		tb.add_theme_stylebox_override("hover", _toggle_box(Color(0.88, 0.8, 0.69)))
		tb.add_theme_stylebox_override("pressed", _toggle_box(Color(0.5, 0.37, 0.27)))
		tb.button_pressed = _variant_choice.get(req.species) == is_real
		tb.pressed.connect(_on_variant_chosen.bind(req.species, is_real))
		hb.add_child(tb)
	return hb


func _card_box() -> StyleBoxFlat:
	var b := StyleBoxFlat.new()
	b.bg_color = Color(0.91, 0.85, 0.75, 0.55)
	b.set_corner_radius_all(14)
	b.set_content_margin_all(16)
	b.border_color = Color(0.547, 0.362, 0.272, 0.5)
	b.set_border_width_all(2)
	return b


func _toggle_box(c: Color) -> StyleBoxFlat:
	var b := StyleBoxFlat.new()
	b.bg_color = c
	b.set_corner_radius_all(12)
	b.set_content_margin_all(8)
	b.border_color = _BORDER
	b.set_border_width_all(2)
	return b


func _on_variant_chosen(species: String, is_real: bool) -> void:
	_variant_choice[species] = is_real
	var quest: QuestData = QuestRegistry.get_quest(_current_id)
	_update_submit(quest, PlayerState.get_quest_status(_current_id))


func _update_submit(quest: QuestData, status: int) -> void:
	if not submit_enabled or status != QuestStatus.ACTIVE:
		_submit.visible = false
		return
	_submit.visible = true
	var offering := _build_offering(quest)
	if offering.is_empty():
		_submit.disabled = true
		_submit.tooltip_text = "You don't have a full set yet"
		return
	var check := PlayerState.can_submit(_current_id, offering)
	_submit.disabled = not check.ok
	_submit.tooltip_text = check.reason
	if check.ok:
		_apply_status_pill_text("Ready to submit", _DONE)


# Override just the pill text/color without rebuilding from status (used for "Ready").
func _apply_status_pill_text(text: String, color: Color) -> void:
	_status_chip.text = text
	var box := StyleBoxFlat.new()
	box.bg_color = color
	box.set_corner_radius_all(14)
	box.content_margin_left = 16
	box.content_margin_right = 16
	box.content_margin_top = 6
	box.content_margin_bottom = 6
	_status_chip.add_theme_stylebox_override("normal", box)


# Builds the submission, or [] if any requirement has no chosen/sufficient variant.
func _build_offering(quest: QuestData) -> Array[SubmissionEntry]:
	var offering: Array[SubmissionEntry] = []
	for req: QuestRequirement in quest.requirements:
		if not _variant_choice.has(req.species):
			return []
		offering.append(SubmissionEntry.new(req.species, _variant_choice[req.species], req.amount))
	return offering


func _on_submit() -> void:
	var quest: QuestData = QuestRegistry.get_quest(_current_id)
	if quest == null:
		return
	var offering := _build_offering(quest)
	if offering.is_empty():
		return
	PlayerState.submit_quest(_current_id, offering)
	# quest_submitted -> _refresh_if_open re-renders into SUBMITTED state


func _status_label(status: int) -> String:
	match status:
		QuestStatus.ACTIVE:
			return "Active"
		QuestStatus.SUBMITTED:
			return "Submitted"
		QuestStatus.MAILED:
			return "Retry"
		QuestStatus.DONE:
			return "Done"
		QuestStatus.FAILED:
			return "Failed"
		_:
			return ""
