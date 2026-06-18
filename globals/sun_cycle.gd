extends DirectionalLight3D

# Rotates the sun as hour progresses.

@export var sunrise_hour: int = 6
@export var sunset_hour: int = 19
@export var camera_lean_deg: float = 38.0 # positive = arc angled towards camera
@export var dawn_angle_deg: float = 18.0
@export var peak_energy: float = 1.0
@export var daylight_knee: float = 0.2
@export var update_interval: float = 0.1 # sun moves <0.5°/s; recompute ~10Hz, not every frame

var _accum: float = 0.0


func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS # allow sun update during day transition screen when time is paused.
	_update_sun()


func _process(delta: float) -> void:
	_accum += delta
	if _accum < update_interval:
		return
	_accum = 0.0
	_update_sun()


func _day_fraction() -> float:
	var frac_hour := GameClock._hour_accumulator / GameClock.seconds_per_hour
	var hour := float(GameClock.current_hour) + frac_hour
	return maxf((hour - sunrise_hour) / float(sunset_hour - sunrise_hour), 0.0)


func _update_sun() -> void:
	var t := _day_fraction()
	var theta0 := deg_to_rad(dawn_angle_deg)
	var theta := lerpf(theta0, PI, t)  # dawn angle at sunrise -> horizon at sunset

	var lean := deg_to_rad(camera_lean_deg)
	var east := Vector3.RIGHT                              # player's right (+X)
	var zenith := Vector3(0.0, cos(lean), sin(lean))       # up, leaned toward camera

	var sun_dir := (east * -cos(theta) + zenith * sin(theta)).normalized()

	var light_dir := -sun_dir
	var up := Vector3.UP if absf(light_dir.dot(Vector3.UP)) < 0.99 else Vector3.BACK
	look_at(global_position + light_dir, up)

	# Fade to full dark as the sun nears the horizon, zero after sunset.
	var daylight := clampf(sun_dir.y / daylight_knee, 0.0, 1.0)
	light_energy = peak_energy * daylight
	shadow_enabled = sun_dir.y > 0.0
