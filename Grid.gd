# Grid.gd
extends Node2D

const GRID_SIZE = 8
const TILE_SIZE = 64
var grid = []

func _ready():
	initialize_grid()

func initialize_grid():
	for x in range(GRID_SIZE):
		grid.append([])
		for y in range(GRID_SIZE):
			var tile = create_tile(x, y)
			grid[x].append(tile)
			add_child(tile)

func create_tile(x, y):
	var tile_scene = preload("res://Tile.tscn")
	var tile = tile_scene.instantiate()
	tile.position = Vector2(x * TILE_SIZE, y * TILE_SIZE)
	tile.grid_position = Vector2(x, y)
	tile.type = randi() % 5  # 5 candy types
	return tile
