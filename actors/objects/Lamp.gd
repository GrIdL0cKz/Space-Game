extends PointLight2D


@export var can_flicker = false


func _ready():
	if can_flicker:
		var rand_time = randf_range(10, 20)
		$Timer.start(rand_time)


func _on_timer_timeout():
	$AnimationPlayer.play('flicker')
