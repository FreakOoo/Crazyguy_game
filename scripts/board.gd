extends Node2D

@export var board_width: int = 8
@export var board_height: int = 8
@export var piece_types: int = 7

const CELL_SIZE: int = 32

var board: Array = []
var piece_scene = preload("res://scenes/tile.tscn")

var is_swapping: bool = false
var selected_piece: Node2D = null

signal move_completed()


func _ready():
	print("Board: _ready() вызван")
	initialize_board()
	print("Board: инициализация завершена, создано фишек: ", count_pieces())

func count_pieces() -> int:
	var count = 0
	for y in range(board_height):
		for x in range(board_width):
			if board[y][x] != null:
				count += 1
	return count

func initialize_board():
	board.resize(board_height)
	for y in range(board_height):
		board[y] = []
		board[y].resize(board_width)
		for x in range(board_width):
			board[y][x] = null

	for y in range(board_height):
		for x in range(board_width):
			var new_piece = create_piece(x, y)
			board[y][x] = new_piece
			add_child(new_piece)

	remove_initial_matches()


func create_piece(x: int, y: int) -> Node2D:
	var new_piece = piece_scene.instantiate()
	var type = randi() % piece_types
	new_piece.init(Vector2(x, y), type)
	new_piece.position = Vector2(x * CELL_SIZE + CELL_SIZE/2, y * CELL_SIZE + CELL_SIZE/2)
	return new_piece


func get_piece_type(x: int, y: int) -> int:
	if x < 0 or x >= board_width or y < 0 or y >= board_height:
		return -1
	var piece = board[y][x]
	if piece == null:
		return -1
	return piece.type


func set_piece(x: int, y: int, piece: Node2D):
	if x < 0 or x >= board_width or y < 0 or y >= board_height:
		return
	board[y][x] = piece
	if piece != null:
		piece.grid_pos = Vector2(x, y)
		piece.position = Vector2(x * CELL_SIZE + CELL_SIZE/2, y * CELL_SIZE + CELL_SIZE/2)


func check_matches() -> Array:
	var matches = []
	for y in range(board_height):
		for x in range(board_width - 2):
			var type = get_piece_type(x, y)
			if type != -1 and type == get_piece_type(x+1, y) and type == get_piece_type(x+2, y):
				matches.append_array(get_line_matches(x, y, Vector2(1, 0), type))
	for x in range(board_width):
		for y in range(board_height - 2):
			var type = get_piece_type(x, y)
			if type != -1 and type == get_piece_type(x, y+1) and type == get_piece_type(x, y+2):
				matches.append_array(get_line_matches(x, y, Vector2(0, 1), type))
	return matches


func get_line_matches(start_x: int, start_y: int, dir: Vector2, type: int) -> Array:
	var result = []
	var x = start_x
	var y = start_y
	while x >= 0 and x < board_width and y >= 0 and y < board_height and get_piece_type(x, y) == type:
		x -= dir.x
		y -= dir.y
	x += dir.x
	y += dir.y
	while x >= 0 and x < board_width and y >= 0 and y < board_height and get_piece_type(x, y) == type:
		result.append(Vector2(x, y))
		x += dir.x
		y += dir.y
	return result


func remove_initial_matches():
	var matches = check_matches()
	while not matches.is_empty():
		for pos in matches:
			var piece = board[pos.y][pos.x]
			if piece != null:
				piece.queue_free()
				board[pos.y][pos.x] = null
		fill_empty_cells()
		matches = check_matches()


func fill_empty_cells():
	for x in range(board_width):
		var write_y = board_height - 1
		for y in range(board_height - 1, -1, -1):
			if board[y][x] != null:
				var piece = board[y][x]
				if y != write_y:
					board[write_y][x] = piece
					board[y][x] = null
					piece.grid_pos = Vector2(x, write_y)
					piece.position = Vector2(x * CELL_SIZE + CELL_SIZE/2, write_y * CELL_SIZE + CELL_SIZE/2)
				write_y -= 1
		for y in range(write_y, -1, -1):
			var new_piece = create_piece(x, y)
			board[y][x] = new_piece
			add_child(new_piece)


func try_swap(pos1: Vector2, pos2: Vector2):
	if is_swapping:
		return
	if abs(pos1.x - pos2.x) + abs(pos1.y - pos2.y) != 1:
		return

	var piece1 = board[pos1.y][pos1.x]
	var piece2 = board[pos2.y][pos2.x]
	if piece1 == null or piece2 == null:
		return

	is_swapping = true

	board[pos1.y][pos1.x] = piece2
	board[pos2.y][pos2.x] = piece1
	piece1.grid_pos = pos2
	piece2.grid_pos = pos1

	animate_piece_move(piece1, pos2)
	animate_piece_move(piece2, pos1)

	await get_tree().create_timer(0.3).timeout

	var matches = check_matches()
	if matches.is_empty():
		board[pos1.y][pos1.x] = piece1
		board[pos2.y][pos2.x] = piece2
		piece1.grid_pos = pos1
		piece2.grid_pos = pos2
		animate_piece_move(piece1, pos1)
		animate_piece_move(piece2, pos2)
		await get_tree().create_timer(0.3).timeout
		is_swapping = false
		return

	await process_matches()
	is_swapping = false
	move_completed.emit()


func animate_piece_move(piece: Node2D, target_grid: Vector2):
	var target_pos = Vector2(target_grid.x * CELL_SIZE + CELL_SIZE/2, target_grid.y * CELL_SIZE + CELL_SIZE/2)
	var tween = create_tween()
	tween.tween_property(piece, "position", target_pos, 0.2)


func process_matches():
	var matches = check_matches()
	while not matches.is_empty():
		for pos in matches:
			var piece = board[pos.y][pos.x]
			if piece != null:
				piece.queue_free()
				board[pos.y][pos.x] = null
		await fill_empty_cells_animated()
		matches = check_matches()


func fill_empty_cells_animated():
	for x in range(board_width):
		var write_y = board_height - 1
		for y in range(board_height - 1, -1, -1):
			if board[y][x] != null:
				var piece = board[y][x]
				if y != write_y:
					board[write_y][x] = piece
					board[y][x] = null
					piece.grid_pos = Vector2(x, write_y)
					animate_piece_move(piece, Vector2(x, write_y))
				write_y -= 1
		for y in range(write_y, -1, -1):
			var new_piece = create_piece(x, y)
			board[y][x] = new_piece
			add_child(new_piece)
			new_piece.position = Vector2(x * CELL_SIZE + CELL_SIZE/2, -CELL_SIZE)
			animate_piece_move(new_piece, Vector2(x, y))
	await get_tree().create_timer(0.3).timeout


func _input(event):
	if is_swapping:
		return
	if event is InputEventMouseButton and event.pressed and event.button_index == MOUSE_BUTTON_LEFT:
		var mouse_pos = get_global_mouse_position()
		var grid_x = floor(mouse_pos.x / CELL_SIZE)
		var grid_y = floor(mouse_pos.y / CELL_SIZE)
		print("gridx: ", grid_x, " gridy: ", grid_y, "\n")
		if grid_x < 0 or grid_x >= board_width or grid_y < 0 or grid_y >= board_height:
			return
		var piece = board[grid_y][grid_x]
		if piece == null:
			return
		print(piece.type)

		if selected_piece == null:
			selected_piece = piece
			selected_piece.scale = Vector2(1.2, 1.2)
		else:
			if selected_piece == piece:
				selected_piece.scale = Vector2(1, 1)
				selected_piece = null
				return
			var pos1 = selected_piece.grid_pos
			var pos2 = piece.grid_pos
			selected_piece.scale = Vector2(1, 1)
			selected_piece = null
			try_swap(pos1, pos2)
