extends Control

## Wires the BoardLogic model to a grid of Cell buttons.

signal game_won
signal game_lost

const CELL_SIZE := 40
const GAME_OVER_SCENE := preload("res://scenes/game_over.tscn")

@onready var grid: GridContainer = $CenterContainer/GridContainer
@onready var status_label: Label = $StatusBar/StatusLabel

var logic: BoardLogic
var cells: Array = []  # Array[Cell], flat y * width + x
var _game_over_overlay: CanvasLayer = null
var _correction_assigned: bool = false
var _flinching_cell: Cell = null
var _flinch_rest_pos: Vector2
var _flinch_tween: Tween = null


func _ready() -> void:
	_start_new_game()


func _start_new_game() -> void:
	if _game_over_overlay and is_instance_valid(_game_over_overlay):
		_game_over_overlay.queue_free()
		_game_over_overlay = null
	var preset := GameSettings.difficulty_preset()
	logic = BoardLogic.new(preset.w, preset.h, preset.mines)
	grid.columns = logic.width
	_correction_assigned = false
	_build_grid()
	_refresh_status()


func _build_grid() -> void:
	cells.clear()
	for child in grid.get_children():
		child.queue_free()
	for y in range(logic.height):
		for x in range(logic.width):
			var c := Cell.new()
			c.grid_pos = Vector2i(x, y)
			c.custom_minimum_size = Vector2(CELL_SIZE, CELL_SIZE)
			c.reveal_requested.connect(_on_cell_reveal)
			c.flag_requested.connect(_on_cell_flag)
			c.mouse_entered.connect(_on_cell_mouse_entered.bind(c))
			c.mouse_exited.connect(_on_cell_mouse_exited)
			grid.add_child(c)
			c.refresh_visual()
			cells.append(c)
	# Pick exactly one cell to be slightly askew. Never acknowledged anywhere.
	var askew: Cell = cells[randi() % cells.size()]
	askew.pivot_offset = Vector2(CELL_SIZE, CELL_SIZE) * 0.5
	var degrees := randf_range(1.0, 3.0)
	if randf() < 0.5:
		degrees = -degrees
	askew.rotation = deg_to_rad(degrees)


func _on_cell_reveal(cell: Cell) -> void:
	var newly := logic.reveal(cell.grid_pos.x, cell.grid_pos.y)
	if not _correction_assigned and logic.mines_placed:
		_assign_correction()
	for i in newly:
		_sync_cell(i)
	if logic.game_over:
		_reveal_all_mines()
		if logic.won:
			game_won.emit()
			status_label.text = "Victory! The dungeon is cleared."
			SfxPlayer.play("victory")
			SfxPlayer.play("well_done")
		else:
			game_lost.emit()
			status_label.text = "You take 1 damage"
			SfxPlayer.play("explosion")
			SfxPlayer.play("big_sux")
		_show_game_over(logic.won)
	else:
		SfxPlayer.play("reveal")
		_refresh_status()


func _on_cell_flag(cell: Cell) -> void:
	var new_state := logic.toggle_flag(cell.grid_pos.x, cell.grid_pos.y)
	if new_state == -1:
		return
	cell.state = new_state
	cell.refresh_visual()
	SfxPlayer.play("flag")
	_refresh_status()


func _sync_cell(flat_index: int) -> void:
	var c: Cell = cells[flat_index]
	c.state = logic.cell_state(c.grid_pos.x, c.grid_pos.y)
	c.is_mine = logic.cell_is_mine(c.grid_pos.x, c.grid_pos.y)
	c.adjacent_mines = logic.cell_adjacent(c.grid_pos.x, c.grid_pos.y)
	c.refresh_visual()
	# Subtle fade-in tween on reveal.
	c.modulate = Color(1, 1, 1, 0.2)
	var tween := create_tween()
	tween.tween_property(c, "modulate", Color(1, 1, 1, 1), 0.18)


func _reveal_all_mines() -> void:
	for y in range(logic.height):
		for x in range(logic.width):
			if logic.cell_is_mine(x, y):
				var c: Cell = cells[logic.idx(x, y)]
				c.state = Cell.State.REVEALED
				c.is_mine = true
				c.refresh_visual()


func _show_game_over(won: bool) -> void:
	_game_over_overlay = GAME_OVER_SCENE.instantiate()
	_game_over_overlay.won = won
	_game_over_overlay.retry_requested.connect(_start_new_game)
	_game_over_overlay.title_requested.connect(_on_back_pressed)
	add_child(_game_over_overlay)


func _assign_correction() -> void:
	# Find all non-mine, non-zero cells and pick three to display "miscounts".
	var candidates: Array[int] = []
	for y in range(logic.height):
		for x in range(logic.width):
			if not logic.cell_is_mine(x, y) and logic.cell_adjacent(x, y) > 0:
				candidates.append(logic.idx(x, y))
	candidates.shuffle()
	var picks: int = mini(3, candidates.size())
	for i in range(picks):
		var target_cell: Cell = cells[candidates[i]]
		var real := logic.cell_adjacent(target_cell.grid_pos.x, target_cell.grid_pos.y)
		var wrong := real
		while wrong == real:
			wrong = randi_range(1, 8)
		target_cell.correction_wrong = wrong
	_correction_assigned = true


func _on_back_pressed() -> void:
	SceneRouter.goto(SceneRouter.TITLE_SCREEN)


func _refresh_status() -> void:
	var flagged := 0
	for c in cells:
		if c.state == Cell.State.FLAGGED:
			flagged += 1
	status_label.text = "Mines: %d  Flags: %d" % [logic.mine_count, flagged]


func _on_cell_mouse_entered(cell: Cell) -> void:
	if logic.game_over or not logic.mines_placed:
		return
	if cell.state != Cell.State.HIDDEN:
		return
	# Only flinch near mines — the hovered cell must be adjacent to one.
	var hx := cell.grid_pos.x
	var hy := cell.grid_pos.y
	if logic.cell_is_mine(hx, hy) or logic.cell_adjacent(hx, hy) == 0:
		return
	# Pick a random neighboring hidden, non-mine cell to flinch.
	var neighbors: Array[Cell] = []
	for dy in range(-1, 2):
		for dx in range(-1, 2):
			if dx == 0 and dy == 0:
				continue
			var nx := hx + dx
			var ny := hy + dy
			if logic.in_bounds(nx, ny):
				var nc: Cell = cells[logic.idx(nx, ny)]
				if nc.state == Cell.State.HIDDEN and not logic.cell_is_mine(nx, ny):
					neighbors.append(nc)
	if neighbors.is_empty():
		return
	var victim: Cell = neighbors[randi() % neighbors.size()]
	_start_flinch(victim, cell)


func _on_cell_mouse_exited() -> void:
	_end_flinch()


func _start_flinch(victim: Cell, source: Cell) -> void:
	_end_flinch()
	_flinching_cell = victim
	_flinch_rest_pos = victim.position
	# Shift away from the hovered cell.
	var dir := Vector2(victim.grid_pos - source.grid_pos).normalized()
	if dir.length_squared() < 0.01:
		dir = Vector2.UP
	var shift := dir * 3.0
	if _flinch_tween and _flinch_tween.is_valid():
		_flinch_tween.kill()
	_flinch_tween = create_tween()
	_flinch_tween.set_trans(Tween.TRANS_ELASTIC).set_ease(Tween.EASE_OUT)
	_flinch_tween.tween_property(victim, "position", _flinch_rest_pos + shift, 0.25)


func _end_flinch() -> void:
	if _flinching_cell and is_instance_valid(_flinching_cell):
		if _flinch_tween and _flinch_tween.is_valid():
			_flinch_tween.kill()
		_flinch_tween = create_tween()
		_flinch_tween.set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
		_flinch_tween.tween_property(
			_flinching_cell, "position",
			_flinch_rest_pos, 0.15)
	_flinching_cell = null
