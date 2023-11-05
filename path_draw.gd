extends Node2D

var draw_path = []
var tile_map : TileMap

var draw_target_position = false

@onready var draw_timer = $Show_Position_Timer

func _ready():
	tile_map = get_tree().get_nodes_in_group("map")[0]
	self.global_position = tile_map.global_position

func _draw():
	if (draw_path.is_empty()):
		return
	
	if draw_target_position:
		draw_circle(tile_map.map_to_local(draw_path[-1]), 8, Color(Color.RED, 0.4))
	
	for index in draw_path.size():
		if index + 1 == draw_path.size():
			continue
		
		var current_point = tile_map.map_to_local(draw_path[index])
		var next_point = tile_map.map_to_local(draw_path[index + 1])
#
		draw_line(current_point, next_point, Color(Color.RED, 0.2), 2.0)

func _on_playable_draw_new_path(new_path):
	draw_target_position = true
	
	draw_path = new_path
	queue_redraw()
	
	if draw_timer.is_stopped():
		draw_timer.start(1)


func _on_show_position_timer_timeout():
	draw_timer.stop()
	draw_target_position = false
