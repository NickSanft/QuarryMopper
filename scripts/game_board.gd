extends Control

## Wires the BoardLogic model to a grid of Cell buttons.

signal game_won
signal game_lost

const CELL_SIZE := 40

@onready var grid: GridContainer = $CenterContainer/GridContainer
@onready var status_label: Label = $StatusBar/StatusLabel

var logic: BoardLogic
var cells: Array = []  # Array[Cell], flat y * width + x


func _ready() -> void:
    var preset := GameSettings.difficulty_preset()
    logic = BoardLogic.new(preset.w, preset.h, preset.mines)
    grid.columns = logic.width
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
            c.text = ""  # placeholder; real textures come in art pass
            c.reveal_requested.connect(_on_cell_reveal)
            c.flag_requested.connect(_on_cell_flag)
            grid.add_child(c)
            cells.append(c)


func _on_cell_reveal(cell: Cell) -> void:
    var newly := logic.reveal(cell.grid_pos.x, cell.grid_pos.y)
    for i in newly:
        _sync_cell(i)
    if logic.game_over:
        if logic.won:
            _reveal_all_mines()
            game_won.emit()
            status_label.text = "Victory! The dungeon is cleared."
        else:
            _reveal_all_mines()
            game_lost.emit()
            status_label.text = "You have perished in the depths..."
    else:
        _refresh_status()


func _on_cell_flag(cell: Cell) -> void:
    var new_state := logic.toggle_flag(cell.grid_pos.x, cell.grid_pos.y)
    if new_state == -1:
        return
    cell.state = new_state
    _refresh_cell_visual(cell)
    _refresh_status()


func _sync_cell(flat_index: int) -> void:
    var c: Cell = cells[flat_index]
    c.state = logic.cell_state(c.grid_pos.x, c.grid_pos.y)
    c.is_mine = logic.cell_is_mine(c.grid_pos.x, c.grid_pos.y)
    c.adjacent_mines = logic.cell_adjacent(c.grid_pos.x, c.grid_pos.y)
    _refresh_cell_visual(c)


func _refresh_cell_visual(c: Cell) -> void:
    # Placeholder text-based visuals; replaced with textures in milestone 4.
    match c.state:
        Cell.State.HIDDEN:
            c.text = ""
        Cell.State.FLAGGED:
            c.text = "F"
        Cell.State.REVEALED:
            if c.is_mine:
                c.text = "X"
            elif c.adjacent_mines > 0:
                c.text = str(c.adjacent_mines)
            else:
                c.text = " "


func _reveal_all_mines() -> void:
    for y in range(logic.height):
        for x in range(logic.width):
            if logic.cell_is_mine(x, y):
                var c: Cell = cells[logic.idx(x, y)]
                c.state = Cell.State.REVEALED
                _refresh_cell_visual(c)


func _on_back_pressed() -> void:
    SceneRouter.goto(SceneRouter.TITLE_SCREEN)


func _refresh_status() -> void:
    var flagged := 0
    for c in cells:
        if c.state == Cell.State.FLAGGED:
            flagged += 1
    status_label.text = "Mines: %d  Flags: %d" % [logic.mine_count, flagged]
