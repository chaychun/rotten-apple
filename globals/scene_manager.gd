extends Node

enum Area_Type {MAIN, BEDROOM}

var areaDict = {
	Area_Type.MAIN: "res://main/main.tscn",
	Area_Type.BEDROOM: "res://main/bedroom.tscn"
}

var lastArea: Area_Type

func change_area(currentArea: Area_Type):
	lastArea = currentArea
