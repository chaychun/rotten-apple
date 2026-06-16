extends Node

@export var currentAreaType: SceneManager.Area_Type
@export var changeAreaType: SceneManager.Area_Type

var get_in_prompt : bool


func _get_out_the_house() -> void:
	SceneManager.change_area(currentAreaType)
	var path = SceneManager.areaDict[changeAreaType]
	print("trying to go to: ", path)
	var err = get_tree().change_scene_to_file(path)
	print("change_scene result: ", err)


func _on_out_area_body_entered(_body: Node3D) -> void:
	if not _body is CharacterBody3D:
		return 
	FadeInOut.transition()
	await FadeInOut.on_transition_finished
	_get_out_the_house()
