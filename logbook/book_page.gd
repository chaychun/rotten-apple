class_name BookPage
extends Control

# Interface for logbook pages. Pokedex & quest implements.

# For book_shell to rerender
signal contents_changed

func go_next() -> void:
	pass


func go_prev() -> void:
	pass


func is_empty() -> bool:
	return true


# Called when this page becomes the active tab (and on logbook open). Refresh data here.
func on_show() -> void:
	pass
