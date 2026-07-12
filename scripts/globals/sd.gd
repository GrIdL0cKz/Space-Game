extends Node
## Diegetic sound. THE RULE: no music, ever - sound only comes from tasks
## and things. `muted_for_eva` kills everything while the player is in
## vacuum; re-entry restores it (and plays the airlock, which is the point).

const DIR := "res://assets/sfx"
const POOL_SIZE := 8

var muted_for_eva: bool = false
var _streams: Dictionary = {}
var _pool: Array[AudioStreamPlayer] = []
var _next: int = 0

func _ready() -> void:
	for i in POOL_SIZE:
		var p := AudioStreamPlayer.new()
		add_child(p)
		_pool.append(p)

func play(name: StringName, vol_db: float = 0.0, pitch: float = 1.0) -> void:
	if muted_for_eva:
		return
	var key := String(name)
	if not _streams.has(key):
		var path := "%s/%s.wav" % [DIR, key]
		if not ResourceLoader.exists(path):
			return
		_streams[key] = load(path)
	var p: AudioStreamPlayer = _pool[_next]
	_next = (_next + 1) % POOL_SIZE
	p.stream = _streams[key]
	p.volume_db = vol_db
	p.pitch_scale = pitch
	p.play()

func set_eva_silence(silent: bool) -> void:
	muted_for_eva = silent
	if silent:
		for p in _pool:
			p.stop()
