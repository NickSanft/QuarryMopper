extends Node

## Persisted game settings. Autoloaded as "GameSettings".

signal settings_changed

const SAVE_PATH := "user://settings.cfg"

const DIFFICULTY_APPRENTICE := 0
const DIFFICULTY_ADVENTURER := 1
const DIFFICULTY_DUNGEON_MASTER := 2
const DIFFICULTY_CUSTOM := 3

var custom_title: String = "Minesweeper"
var difficulty: int = DIFFICULTY_APPRENTICE
var custom_width: int = 9
var custom_height: int = 9
var custom_mines: int = 10
var music_volume: float = 0.8
var sfx_volume: float = 1.0
var fullscreen: bool = false


func _ready() -> void:
    load_settings()


func difficulty_preset() -> Dictionary:
    match difficulty:
        DIFFICULTY_APPRENTICE:
            return {"w": 9, "h": 9, "mines": 10}
        DIFFICULTY_ADVENTURER:
            return {"w": 16, "h": 16, "mines": 40}
        DIFFICULTY_DUNGEON_MASTER:
            return {"w": 30, "h": 16, "mines": 99}
        _:
            return {"w": custom_width, "h": custom_height, "mines": custom_mines}


func save() -> void:
    var cfg := ConfigFile.new()
    cfg.set_value("title", "custom_title", custom_title)
    cfg.set_value("game", "difficulty", difficulty)
    cfg.set_value("game", "custom_width", custom_width)
    cfg.set_value("game", "custom_height", custom_height)
    cfg.set_value("game", "custom_mines", custom_mines)
    cfg.set_value("audio", "music_volume", music_volume)
    cfg.set_value("audio", "sfx_volume", sfx_volume)
    cfg.set_value("video", "fullscreen", fullscreen)
    cfg.save(SAVE_PATH)
    settings_changed.emit()


func load_settings() -> void:
    var cfg := ConfigFile.new()
    if cfg.load(SAVE_PATH) != OK:
        return
    custom_title = cfg.get_value("title", "custom_title", custom_title)
    difficulty = cfg.get_value("game", "difficulty", difficulty)
    custom_width = cfg.get_value("game", "custom_width", custom_width)
    custom_height = cfg.get_value("game", "custom_height", custom_height)
    custom_mines = cfg.get_value("game", "custom_mines", custom_mines)
    music_volume = cfg.get_value("audio", "music_volume", music_volume)
    sfx_volume = cfg.get_value("audio", "sfx_volume", sfx_volume)
    fullscreen = cfg.get_value("video", "fullscreen", fullscreen)
