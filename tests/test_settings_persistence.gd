extends GdUnitTestSuite

## Exercises GameSettings save/load round-trip via a fresh instance, so the
## autoloaded singleton's state is not disturbed.

const GameSettingsScript := preload("res://scripts/autoload/game_settings.gd")


func before_test() -> void:
    # Remove any existing save so tests start clean.
    if FileAccess.file_exists(GameSettingsScript.SAVE_PATH):
        DirAccess.remove_absolute(ProjectSettings.globalize_path(GameSettingsScript.SAVE_PATH))


func test_save_and_load_round_trip() -> void:
    var a: Node = auto_free(GameSettingsScript.new())
    a.custom_title = "Doomsweeper"
    a.difficulty = GameSettingsScript.DIFFICULTY_ADVENTURER
    a.custom_width = 12
    a.custom_height = 14
    a.custom_mines = 25
    a.music_volume = 0.42
    a.sfx_volume = 0.73
    a.fullscreen = true
    a.save()

    var b: Node = auto_free(GameSettingsScript.new())
    b.load_settings()

    assert_str(b.custom_title).is_equal("Doomsweeper")
    assert_int(b.difficulty).is_equal(GameSettingsScript.DIFFICULTY_ADVENTURER)
    assert_int(b.custom_width).is_equal(12)
    assert_int(b.custom_height).is_equal(14)
    assert_int(b.custom_mines).is_equal(25)
    assert_float(b.music_volume).is_equal_approx(0.42, 0.001)
    assert_float(b.sfx_volume).is_equal_approx(0.73, 0.001)
    assert_bool(b.fullscreen).is_true()


func test_load_with_no_file_keeps_defaults() -> void:
    var s: Node = auto_free(GameSettingsScript.new())
    s.load_settings()
    assert_str(s.custom_title).is_equal("Minesweeper")
    assert_int(s.difficulty).is_equal(GameSettingsScript.DIFFICULTY_APPRENTICE)


func test_difficulty_preset_returns_expected_sizes() -> void:
    var s: Node = auto_free(GameSettingsScript.new())
    s.difficulty = GameSettingsScript.DIFFICULTY_APPRENTICE
    assert_int(s.difficulty_preset()["mines"]).is_equal(10)
    s.difficulty = GameSettingsScript.DIFFICULTY_ADVENTURER
    assert_int(s.difficulty_preset()["mines"]).is_equal(40)
    s.difficulty = GameSettingsScript.DIFFICULTY_DUNGEON_MASTER
    assert_int(s.difficulty_preset()["mines"]).is_equal(99)
