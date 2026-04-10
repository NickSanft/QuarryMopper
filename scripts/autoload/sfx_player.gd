extends Node

## Centralized SFX playback. Autoloaded as "SfxPlayer".

const SOUNDS := {
    "reveal": preload("res://resources/audio/reveal.ogg"),
    "flag": preload("res://resources/audio/flag.ogg"),
    "explosion": preload("res://resources/audio/explosion.ogg"),
    "victory": preload("res://resources/audio/victory.ogg"),
}

const POOL_SIZE := 6

var _players: Array[AudioStreamPlayer] = []
var _next: int = 0


func _ready() -> void:
    for i in range(POOL_SIZE):
        var p := AudioStreamPlayer.new()
        add_child(p)
        _players.append(p)


func play(sound_name: String) -> void:
    if not SOUNDS.has(sound_name):
        return
    var p := _players[_next]
    _next = (_next + 1) % POOL_SIZE
    p.stream = SOUNDS[sound_name]
    p.volume_db = linear_to_db(max(GameSettings.sfx_volume, 0.0001))
    p.play()
