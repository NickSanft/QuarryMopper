extends GdUnitTestSuite

const BoardLogicScript := preload("res://scripts/board_logic.gd")


func test_flood_fill_reveals_zero_region() -> void:
    # With a 9x9 board and only 1 mine, clicking far from the mine should
    # flood-reveal a large contiguous region.
    var board: BoardLogic = BoardLogicScript.new(9, 9, 1, 1)
    var newly := board.reveal(0, 0)
    assert_int(newly.size()).is_greater(1)
    # Nothing revealed should be a mine.
    for i in newly:
        var y := i / 9
        var x := i % 9
        assert_bool(board.cell_is_mine(x, y)).is_false()


func test_flood_fill_does_not_reveal_mines() -> void:
    var board: BoardLogic = BoardLogicScript.new(9, 9, 10, 5)
    board.reveal(0, 0)
    for y in range(9):
        for x in range(9):
            if board.cell_is_mine(x, y):
                assert_int(board.cell_state(x, y)).is_equal(BoardLogicScript.STATE_HIDDEN)


func test_revealing_numbered_cell_only_reveals_itself() -> void:
    # Dense board: any non-mine cell adjacent to the mine cluster will be numbered.
    var board: BoardLogic = BoardLogicScript.new(5, 5, 20, 11)
    # Force mines placement via a first click in a corner.
    board.reveal(0, 0)
    var target := Vector2i(-1, -1)
    for y in range(5):
        for x in range(5):
            if board.cell_state(x, y) == BoardLogicScript.STATE_HIDDEN \
                    and not board.cell_is_mine(x, y) \
                    and board.cell_adjacent(x, y) > 0:
                target = Vector2i(x, y)
                break
        if target.x >= 0:
            break
    if target.x < 0:
        return  # No hidden numbered cell left; nothing to assert.
    var newly := board.reveal(target.x, target.y)
    assert_int(newly.size()).is_equal(1)
