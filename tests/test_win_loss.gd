extends GdUnitTestSuite

const BoardLogicScript := preload("res://scripts/board_logic.gd")


func test_revealing_mine_ends_game_as_loss() -> void:
    var board: BoardLogic = BoardLogicScript.new(9, 9, 10, 42)
    board.reveal(0, 0)  # first click, places mines safely
    # Find any mine and reveal it.
    for y in range(9):
        for x in range(9):
            if board.cell_is_mine(x, y):
                board.reveal(x, y)
                assert_bool(board.game_over).is_true()
                assert_bool(board.won).is_false()
                return
    fail("No mines found on board")


func test_revealing_all_non_mines_is_a_win() -> void:
    var board: BoardLogic = BoardLogicScript.new(5, 5, 3, 77)
    board.reveal(0, 0)
    # Reveal every remaining non-mine hidden cell.
    for y in range(5):
        for x in range(5):
            if not board.cell_is_mine(x, y) \
                    and board.cell_state(x, y) == BoardLogicScript.STATE_HIDDEN:
                board.reveal(x, y)
    assert_bool(board.game_over).is_true()
    assert_bool(board.won).is_true()


func test_flag_prevents_no_ops_after_game_over() -> void:
    var board: BoardLogic = BoardLogicScript.new(4, 4, 2, 3)
    board.reveal(0, 0)
    for y in range(4):
        for x in range(4):
            if board.cell_is_mine(x, y):
                board.reveal(x, y)
                break
        if board.game_over:
            break
    assert_bool(board.game_over).is_true()
    # Further actions should not mutate state.
    var result := board.toggle_flag(1, 1)
    assert_int(result).is_equal(-1)
