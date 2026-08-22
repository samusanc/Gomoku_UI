extends ColorRect

## Drives the game background shader. It takes its own time uniforms instead of
## reading TIME, so the animation is fed from here.

@export var paint_speed := 1.0
@export var spin_speed := 1.0

var elapsed := 0.0


func _process(delta: float) -> void:
	elapsed += delta
	var mat: ShaderMaterial = material
	mat.set_shader_parameter("time_val", elapsed * paint_speed)
	mat.set_shader_parameter("spin_time", elapsed * spin_speed)
