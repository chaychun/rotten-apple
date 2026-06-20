extends Node
# SoundManager autoload

const POOL_SIZE := 8

@export var sfx_footstep: Array[AudioStream] = []
@export var sfx_jump: AudioStream
@export var sfx_door_in: AudioStream
@export var sfx_door_out: AudioStream
@export var sleep: AudioStream
@export var mailbox: AudioStream
@export var sfx_lasso_charge: AudioStream
@export var sfx_lasso_throw: AudioStream
@export var sfx_lasso_hit: Array[AudioStream] = []
@export var sfx_catch_success: AudioStream
@export var sfx_catch_fail: AudioStream
@export var sfx_skillcheck_tick: Array[AudioStream] = []
@export var sfx_skillcheck_miss: Array[AudioStream] = []
@export var sfx_book_tab: AudioStream
@export var sfx_page_flip: AudioStream
@export var sfx_ui_click: AudioStream
@export var sfx_ui_hover: AudioStream
@export var sfx_ui_select: AudioStream

@export_group("Ambient Music")
@export var ambient_tracks: Array[AudioStream] = []
@export var ambient_min_wait: float = 30.0
@export var ambient_max_wait: float = 120.0
@export var ambient_fade_in: float = 1.5
@export var ambient_fade_out: float = 1.5

var _sfx_pool: Array[AudioStreamPlayer] = []
var _pool_index := 0
var _ambient_timer: Timer
var _ambient_last_index: int = -1
var _ambient_enabled: bool = true
var _day_start_pending: bool = false

@onready var _music_player: AudioStreamPlayer = AudioStreamPlayer.new()


func _ready() -> void:
	for i in POOL_SIZE:
		var p := AudioStreamPlayer.new()
		p.bus = "SFX"
		add_child(p)
		_sfx_pool.append(p)

	_music_player.bus = "Music"
	_music_player.process_mode = Node.PROCESS_MODE_ALWAYS  # keep music playing through pause
	add_child(_music_player)
	_music_player.finished.connect(_on_ambient_track_finished)

	_ambient_timer = Timer.new()
	_ambient_timer.one_shot = true
	add_child(_ambient_timer)
	_ambient_timer.timeout.connect(_play_next_ambient_track)
	
	_connect_existing_buttons(get_tree().root)
	get_tree().node_added.connect(_on_node_added)
	
	Events.lasso_thrown.connect(func() -> void: play_sfx(sfx_lasso_throw, -10.0))
	Events.animal_caught.connect(func(_id: String) -> void: play_sfx(sfx_catch_success, -6.7))
	Events.lasso_hit.connect(func() -> void: play_sfx(sfx_lasso_hit.pick_random(), -5.0))
	Events.day_started.connect(_on_day_started)	
	_start_ambient_wait()
	


func play_sfx(stream: AudioStream, volume_db: float = 0.0, pitch: float = 1.0) -> AudioStreamPlayer:
	if stream == null:
		return null
	var p := _sfx_pool[_pool_index]
	_pool_index = (_pool_index + 1) % POOL_SIZE
	p.stream = stream
	p.volume_db = volume_db
	p.pitch_scale = pitch
	p.play()
	return p


func _on_day_started(_day: int) -> void:
	_ambient_timer.stop()
	_music_player.stop()
	_day_start_pending = true
	await get_tree().create_timer(8.0).timeout
	_play_next_ambient_track()
	if _day_start_pending:
		_play_next_ambient_track()


func _start_ambient_wait() -> void:
	if not _ambient_enabled or ambient_tracks.is_empty():
		return
	var wait_time: float = randf_range(ambient_min_wait, ambient_max_wait)
	_ambient_timer.start(wait_time)


func _play_next_ambient_track() -> void:
	if not _ambient_enabled or ambient_tracks.is_empty():
		return
	
	var index: int = _pick_ambient_index()
	_ambient_last_index = index
	
	_music_player.stream = ambient_tracks[index]
	_music_player.volume_db = -40.0
	_music_player.play()
	
	var tween := create_tween()
	tween.tween_property(_music_player, "volume_db", 0.0, ambient_fade_in)


func _pick_ambient_index() -> int:
	if ambient_tracks.size() == 1:
		return 0
	var index: int = randi() % ambient_tracks.size()
	while index == _ambient_last_index:
		index = randi() % ambient_tracks.size()
	return index


func _on_ambient_track_finished() -> void:
	_start_ambient_wait()


func set_ambient_enabled(value: bool) -> void:
	_ambient_enabled = value
	if not _ambient_enabled:
		_ambient_timer.stop()
		var tween := create_tween()
		tween.tween_property(_music_player, "volume_db", -40.0, ambient_fade_out)
		tween.tween_callback(_music_player.stop)
	else:
		_start_ambient_wait()


func _connect_existing_buttons(node: Node) -> void:
	if node is BaseButton:
		_connect_button(node)
	for child in node.get_children():
		_connect_existing_buttons(child)


func _connect_button(button: BaseButton) -> void:
	if not button.pressed.is_connected(_on_button_pressed):
		button.pressed.connect(_on_button_pressed)
	if not button.mouse_entered.is_connected(_on_button_hovered):
		button.mouse_entered.connect(_on_button_hovered)


func _on_button_pressed() -> void:
	play_sfx(sfx_ui_click, -6.7)


func _on_button_hovered() -> void:
	play_sfx(sfx_ui_hover, -6.7)


func _on_node_added(node: Node) -> void:
	if node is BaseButton:
		(node as BaseButton).pressed.connect(func() -> void: play_sfx(sfx_ui_click, -10.0))
		(node as BaseButton).mouse_entered.connect(func() -> void: play_sfx(sfx_ui_hover, -10.0))
