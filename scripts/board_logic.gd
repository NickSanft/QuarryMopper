class_name BoardLogic
extends RefCounted

## Pure-logic Minesweeper board model. No scene-tree dependencies; fully unit-testable.

const STATE_HIDDEN := 0
const STATE_REVEALED := 1
const STATE_FLAGGED := 2

var width: int
var height: int
var mine_count: int

# Flat arrays indexed as y * width + x.
var is_mine: PackedByteArray
var adjacent: PackedByteArray
var state: PackedByteArray

var mines_placed: bool = false
var revealed_count: int = 0
var game_over: bool = false
var won: bool = false

# Optional injection point for deterministic tests.
var rng: RandomNumberGenerator


func _init(w: int, h: int, mines: int, seed_value: int = -1) -> void:
	assert(w > 0 and h > 0)
	assert(mines >= 0 and mines < w * h)
	width = w
	height = h
	mine_count = mines
	var n := w * h
	is_mine = PackedByteArray()
	is_mine.resize(n)
	adjacent = PackedByteArray()
	adjacent.resize(n)
	state = PackedByteArray()
	state.resize(n)
	rng = RandomNumberGenerator.new()
	if seed_value >= 0:
		rng.seed = seed_value
	else:
		rng.randomize()


func idx(x: int, y: int) -> int:
	return y * width + x


func in_bounds(x: int, y: int) -> bool:
	return x >= 0 and y >= 0 and x < width and y < height


## Place mines after the first click, guaranteeing the clicked cell and its
## 8 neighbors are mine-free.
func place_mines(safe_x: int, safe_y: int) -> void:
	assert(not mines_placed)
	var n := width * height
	var safe_set := {}
	for dy in range(-1, 2):
		for dx in range(-1, 2):
			var nx := safe_x + dx
			var ny := safe_y + dy
			if in_bounds(nx, ny):
				safe_set[idx(nx, ny)] = true

	var candidates: Array[int] = []
	for i in range(n):
		if not safe_set.has(i):
			candidates.append(i)

	# Fisher-Yates partial shuffle.
	for i in range(min(mine_count, candidates.size())):
		var j := rng.randi_range(i, candidates.size() - 1)
		var tmp := candidates[i]
		candidates[i] = candidates[j]
		candidates[j] = tmp
		is_mine[candidates[i]] = 1

	_count_neighbors()
	mines_placed = true


func _count_neighbors() -> void:
	for y in range(height):
		for x in range(width):
			if is_mine[idx(x, y)] == 1:
				continue
			var c := 0
			for dy in range(-1, 2):
				for dx in range(-1, 2):
					if dx == 0 and dy == 0:
						continue
					var nx := x + dx
					var ny := y + dy
					if in_bounds(nx, ny) and is_mine[idx(nx, ny)] == 1:
						c += 1
			adjacent[idx(x, y)] = c


## Reveal a cell. Returns the array of indices that became revealed
## (useful for view layer animation). Sets game_over / won as appropriate.
func reveal(x: int, y: int) -> PackedInt32Array:
	var newly := PackedInt32Array()
	if game_over or not in_bounds(x, y):
		return newly
	if not mines_placed:
		place_mines(x, y)
	var start := idx(x, y)
	if state[start] != STATE_HIDDEN:
		return newly

	if is_mine[start] == 1:
		state[start] = STATE_REVEALED
		newly.append(start)
		game_over = true
		won = false
		return newly

	# BFS flood fill across zero-adjacent regions.
	var queue: Array[int] = [start]
	while queue.size() > 0:
		var i: int = queue.pop_back()
		if state[i] != STATE_HIDDEN:
			continue
		state[i] = STATE_REVEALED
		revealed_count += 1
		newly.append(i)
		if adjacent[i] != 0:
			continue
		var cy := i / width
		var cx := i % width
		for dy in range(-1, 2):
			for dx in range(-1, 2):
				if dx == 0 and dy == 0:
					continue
				var nx := cx + dx
				var ny := cy + dy
				if in_bounds(nx, ny):
					var ni := idx(nx, ny)
					if state[ni] == STATE_HIDDEN and is_mine[ni] == 0:
						queue.append(ni)

	if revealed_count >= width * height - mine_count:
		game_over = true
		won = true
	return newly


## Toggle a flag on a hidden cell. Returns the new state.
func toggle_flag(x: int, y: int) -> int:
	if game_over or not in_bounds(x, y):
		return -1
	var i := idx(x, y)
	if state[i] == STATE_HIDDEN:
		state[i] = STATE_FLAGGED
	elif state[i] == STATE_FLAGGED:
		state[i] = STATE_HIDDEN
	return state[i]


func cell_state(x: int, y: int) -> int:
	return state[idx(x, y)]


func cell_is_mine(x: int, y: int) -> bool:
	return is_mine[idx(x, y)] == 1


func cell_adjacent(x: int, y: int) -> int:
	return adjacent[idx(x, y)]
