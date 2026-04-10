extends GdUnitTestSuite

const BoardLogicScript := preload("res://scripts/board_logic.gd")


func test_mine_count_matches_requested() -> void:
    var board: BoardLogic = BoardLogicScript.new(9, 9, 10, 42)
    board.place_mines(0, 0)
    var count := 0
    for y in range(9):
        for x in range(9):
            if board.cell_is_mine(x, y):
                count += 1
    assert_int(count).is_equal(10)


func test_first_click_and_neighbors_are_safe() -> void:
    var board: BoardLogic = BoardLogicScript.new(9, 9, 10, 123)
    var safe_x := 4
    var safe_y := 4
    board.place_mines(safe_x, safe_y)
    for dy in range(-1, 2):
        for dx in range(-1, 2):
            var x := safe_x + dx
            var y := safe_y + dy
            if board.in_bounds(x, y):
                assert_bool(board.cell_is_mine(x, y)).is_false()


func test_adjacent_counts_in_valid_range() -> void:
    var board: BoardLogic = BoardLogicScript.new(16, 16, 40, 7)
    board.place_mines(0, 0)
    for y in range(16):
        for x in range(16):
            if not board.cell_is_mine(x, y):
                var a := board.cell_adjacent(x, y)
                assert_int(a).is_between(0, 8)


func test_adjacent_counts_match_neighbor_mines() -> void:
    var board: BoardLogic = BoardLogicScript.new(9, 9, 10, 99)
    board.place_mines(4, 4)
    for y in range(9):
        for x in range(9):
            if board.cell_is_mine(x, y):
                continue
            var expected := 0
            for dy in range(-1, 2):
                for dx in range(-1, 2):
                    if dx == 0 and dy == 0:
                        continue
                    var nx := x + dx
                    var ny := y + dy
                    if board.in_bounds(nx, ny) and board.cell_is_mine(nx, ny):
                        expected += 1
            assert_int(board.cell_adjacent(x, y)).is_equal(expected)
