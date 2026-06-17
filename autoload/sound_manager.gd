extends Node
# SoundManager autoload

const POOL_SIZE := 8

@export var sfx_lasso_throw: AudioStream
@export var sfx_lasso_hit: AudioStream
@export var sfx_catch_success: AudioStream
@export var sfx_catch_fail: AudioStream
@export var sfx_skillcheck_tick: AudioStream
@export var sfx_skillcheck_miss: AudioStream

var _sfx_pool: Array[AudioStreamPlayer] = []
var _pool_index := 0

@onready var _music_player: AudioStreamPlayer = AudioStreamPlayer.new()


func _ready() -> void:
	for i in POOL_SIZE:
		var p := AudioStreamPlayer.new()
		p.bus = "SFX"
		add_child(p)
		_sfx_pool.append(p)
	
	_music_player.bus = "Music"
	add_child(_music_player)
	
	Events.lasso_thrown.connect(func() -> void: play_sfx(sfx_lasso_throw))
	Events.animal_caught.connect(func(_id: String) -> void: play_sfx(sfx_catch_success))


func play_sfx(stream: AudioStream, volume_db: float = 0.0, pitch: float = 1.0) -> void:
	if stream == null:
		return
	var p := _sfx_pool[_pool_index]
	_pool_index = (_pool_index + 1) % POOL_SIZE
	p.stream = stream
	p.volume_db = volume_db
	p.pitch_scale = pitch
	p.play()


func play_music(stream: AudioStream, fade_in: float = 0.5) -> void:
	if _music_player.stream == stream and _music_player.playing:
		return
	_music_player.stream = stream
	_music_player.volume_db = -40.0
	_music_player.play()
	var tween := create_tween()
	tween.tween_property(_music_player, "volume_db", 0.0, fade_in)


func stop_music(fade_out: float = 0.5) -> void:
	var tween := create_tween()
	tween.tween_property(_music_player, "volume_db", -40.0, fade_out)
	tween.tween_callback(_music_player.stop)
