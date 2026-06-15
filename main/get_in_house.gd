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
	var path = SceneManager.areaDict[changeAreaType]
	print("trying to go to: ", path)
	var err = get_tree().change_scene_to_file(path)
	print("change_scene result: ", err)


func _on_in_area_body_entered(body: CharacterBody3D) -> void:
	FadeInOut.transition()
	await FadeInOut.on_transition_finished
	_get_in_the_house()
