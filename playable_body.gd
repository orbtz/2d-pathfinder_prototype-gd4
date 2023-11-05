extends CharacterBody2D

@onready var nav_agent = $NavigationAgent2D
@export var SPEED: float = 1

# bloco para validar a movimentação por grid
@export var tile_map : TileMap
var astar_grid: AStarGrid2D
var is_moving: bool
var target_position: Vector2 = Vector2(0, 0)
var next_iteration_position: Vector2

signal draw_new_path 

#https://www.youtube.com/watch?v=qJKBT3KOLiY
func _ready():
	astar_grid = AStarGrid2D.new()
	astar_grid.size = Vector2i(tile_map.get_used_rect().size)
	astar_grid.cell_size = Vector2(16, 16)
	astar_grid.diagonal_mode = AStarGrid2D.DIAGONAL_MODE_NEVER
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
			
			if tile_data == null or not tile_data.get_custom_data("walkable"):
				astar_grid.set_point_solid(tile_position)

func _update_pathfinding(new_target_position):
	if new_target_position == Vector2.ZERO:
		return
	
	target_position = new_target_position

func _process(delta):
	if is_moving:
		return
		
	if target_position == Vector2(0, 0):
		return
	
	move()

func move():
	var other_playables = get_tree().get_nodes_in_group("playable")
	var occupied_tiles = []
	
	for other_playable in other_playables:
		if other_playable == self:
			continue
		occupied_tiles.append(tile_map.local_to_map(other_playable.global_position))
	
	for occupied_tile in occupied_tiles:
		astar_grid.set_point_solid(occupied_tile)
	
	var path = astar_grid.get_id_path(
		tile_map.local_to_map(global_position),
		tile_map.local_to_map(target_position)
	)
	
	for occupied_tile in occupied_tiles:
		astar_grid.set_point_solid(occupied_tile, false)
	
#	get_tree().call_group("main_group", "_draw_path", path)
	draw_new_path.emit(path)
	
	path.pop_front()
	
	if path.is_empty():
		return
	
	next_iteration_position = tile_map.map_to_local(path[0])
	is_moving = true

func _physics_process(delta):
	if is_moving:
		position = global_position.move_toward(next_iteration_position, SPEED)
		
		if global_position != next_iteration_position:
			return
		
		is_moving = false
