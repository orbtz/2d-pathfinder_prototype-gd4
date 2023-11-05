extends Node2D

@onready var body = $CharacterBody2D

func _ready():
	var group_name = get_groups()[0]
	
	get_tree().call_group("playable", "_check_object_for_target", group_name, body)
