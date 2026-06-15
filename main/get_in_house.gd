extends Node

@export var currentAreaType: SceneManager.Area_Type
@export var changeAreaType: SceneManager.Area_Type


var get_in_prompt : bool

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	pass # Replace with function body.


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	pass


func _get_in_the_house() -> void:
	SceneManager.change_area(currentAreaType)
	get_tree().change_scene_to_file(SceneManager.areaDict[changeAreaType])


func _on_in_area_body_entered(body: CharacterBody3D) -> void:
	_get_in_the_house()
	print("yej")
