extends Node2D

@export var SPEED: float = 1

@export var tile_map : TileMap
@export var object_target_group : String
var object_target_body

@onready var body : CharacterBody2D = $CharacterBody2D
@onready var activate_timer : Timer = $activate_playable_timer

var astar_grid: AStarGrid2D
var is_moving: bool
var target_position: Vector2 = Vector2(0, 0)
var next_iteration_position: Vector2

var is_active = false

signal draw_new_path 

#https://www.youtube.com/watch?v=qJKBT3KOLiY
func _ready():
	var rng
	rng = RandomNumberGenerator.new()
	
	activate_timer.start(rng.randf_range(0.0, 2.0))
	
	SPEED = rng.randf_range(4.2, 5.0)
	
	astar_grid = AStarGrid2D.new()
	astar_grid.size = Vector2i(tile_map.get_used_rect().size)
	astar_grid.cell_size = Vector2(16, 16)
	astar_grid.diagonal_mode = AStarGrid2D.DIAGONAL_MODE_ONLY_IF_NO_OBSTACLES
	astar_grid.default_compute_heuristic = AStarGrid2D.HEURISTIC_EUCLIDEAN
	astar_grid.update()
	
	var region_size = astar_grid.size
	var region_position = Vector2i(0, 0)
	
	for x in region_size.x:
		for y in region_size.y:
			var tile_position = Vector2(
				x + region_position.x,
				y + region_position.y
			)
			
			var tile_data = tile_map.get_cell_tile_data(0, tile_position)
			var tile_data_wall = tile_map.get_cell_tile_data(1, tile_position)
			
			if not tile_data_wall == null and not tile_data_wall.get_custom_data("walkable"):
				astar_grid.set_point_solid(tile_position)
			elif tile_data == null or not tile_data.get_custom_data("walkable"):
				astar_grid.set_point_solid(tile_position)

func _check_object_for_target(object_group, object_body):
	if object_group == object_target_group:
		object_target_body = object_body
		_update_pathfinding(object_body.global_position, false)
		
func _move_to_object_target():
	if not object_target_body == null:
		_update_pathfinding(object_target_body.global_position, false)

func _update_pathfinding(new_target_position, needs_to_be_selected = true):
	if needs_to_be_selected and not is_in_group("selected"):
		return
	
#	if new_target_position == Vector2.ZERO:
#		return
	
	var other_playables = get_tree().get_nodes_in_group("playable")

	for index in other_playables.size():
		var other_playable = other_playables[index]
		
		if other_playable != self:
			continue
		
		var fixed_index
		if needs_to_be_selected:
			fixed_index = index + 1
		else:
			fixed_index =  1
			
		var tile_occupied = tile_map.get_cell_tile_data(0, target_position)
		
		if tile_occupied != null:
			tile_occupied.set_custom_data("occupied", false)

		var next_position = get_new_position(fixed_index, new_target_position)
		
		while true:
			var tile_data = tile_map.get_cell_tile_data(0, tile_map.local_to_map(next_position))
			
			if tile_data == null or not tile_data.get_custom_data("walkable"):
				fixed_index = fixed_index + 1
				next_position = get_new_position(fixed_index, new_target_position)
			else:
				tile_data.set_custom_data("occupied", true)
				break

		target_position = next_position
		return

func get_new_position(fixed_index, pivot_position):
	var return_value
	
	if fixed_index == 1:
		return_value = pivot_position
	elif (fixed_index)%4 == 0:
		return_value = Vector2(pivot_position.x + ((fixed_index/4) * 16), pivot_position.y)
	elif (fixed_index)%3 == 0:
		return_value = Vector2(pivot_position.x - ((fixed_index/3) * 16), pivot_position.y)
	elif (fixed_index)%2 == 0:
		return_value = Vector2(pivot_position.x, pivot_position.y + ((fixed_index/2) * 16))
	else:
		return_value = Vector2(pivot_position.x, pivot_position.y - ((fixed_index) * 16))
	
	return return_value

func _process(delta):
	if is_moving:
		return
		
	if not is_active:
		return
		
	if target_position == Vector2(0, 0):
		return
	
	move()

func move():
	var path = astar_grid.get_id_path(
		tile_map.local_to_map(body.global_position),
		tile_map.local_to_map(target_position)
	)
	
	draw_new_path.emit(path)
	
	path.pop_front()
	
	if path.is_empty():
		return
	
	next_iteration_position = tile_map.map_to_local(path[0])
	is_moving = true

func _physics_process(delta):
	if is_moving:
		
		body.global_position = body.global_position.move_toward(next_iteration_position, SPEED)
		
		if body.global_position != next_iteration_position:
			return
		
		is_moving = false

func _update_if_selected(body_array):
	for item in body_array:
		if item.rid == body.get_rid():
			add_to_group("selected")
			return
	
	if is_in_group("selected"):
		remove_from_group("selected")

func _on_activate_playable_timer_timeout():
	is_active = true
