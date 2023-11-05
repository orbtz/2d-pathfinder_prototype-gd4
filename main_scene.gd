@tool
extends Node2D

@onready var tile_map = $tilemap_main

# https://kidscancode.org/godot_recipes/4.x/input/multi_unit_select/index.html
var dragging = false  # Are we currently dragging?
var selected = []  # Array of selected units.
var drag_start = Vector2.ZERO  # Location where drag began.
var select_rect = RectangleShape2D.new()  # Collision shape for drag box.

func _input(event):
	if Input.is_action_just_pressed("left_click"):
		var mouse_pos = get_viewport().get_mouse_position()
		get_tree().call_group("playable", "_update_pathfinding", mouse_pos)
	elif Input.is_action_just_pressed("reset_position"):
		get_tree().call_group("playable", "_move_to_object_target")
	elif Input.is_action_just_pressed("right_click"):
		dragging = true
		drag_start = event.position
	elif Input.is_action_just_released("right_click"):
		dragging = false
		
		queue_redraw()
		
		var drag_end = event.position
		select_rect.extents = abs(drag_end - drag_start) / 2
		
		var space = tile_map.get_world_2d().direct_space_state
		var query = PhysicsShapeQueryParameters2D.new()
		query.shape = select_rect
		query.collision_mask = 1  # Units are on collision layer 1
		query.transform = Transform2D(0, (drag_end + drag_start) / 2)
		
		selected = space.intersect_shape(query)
		
		if not selected.is_empty():
			get_tree().call_group("playable", "_update_if_selected", selected)
	
	if event is InputEventMouseMotion and dragging:
		queue_redraw()

func _draw():
	if dragging:
		draw_rect(Rect2(drag_start, get_global_mouse_position() - drag_start), Color.DARK_RED, false, 2.0)
