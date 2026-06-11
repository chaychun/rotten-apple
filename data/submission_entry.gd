class_name SubmissionEntry
extends RefCounted

# Built at runtime by the frontend (no static .tres)

var species: String
var is_real: bool
var amount: int


# note to self: p_* is godot convention
func _init(p_species := "", p_is_real := true, p_amount := 0) -> void:
	species = p_species
	is_real = p_is_real
	amount = p_amount
