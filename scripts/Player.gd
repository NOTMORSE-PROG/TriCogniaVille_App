extends CharacterBody2D
## Player.gd — top-down 8-directional movement.
## Visual is built procedurally by Main.gd (no sprites needed).
## Joystick reference stored in meta "joystick_ref" by Main.gd.

const SPEED : float = 280.0

func _physics_process(_delta: float) -> void:
	if QuestManager.is_quest_active():
		velocity = Vector2.ZERO
		var _fd := get_node_or_null("FootDust") as CPUParticles2D
		if is_instance_valid(_fd):
			_fd.emitting = false
		return
	var dir := _get_direction()
	velocity = velocity.lerp(dir * SPEED, 0.18)
	move_and_slide()
	# Flip sprite to face movement direction (horizontal only)
	if dir.x != 0.0:
		var spr := get_node_or_null("Sprite") as Sprite2D
		if spr:
			spr.flip_h = dir.x < 0.0
	# Toggle footstep dust based on movement
	var foot_dust := get_node_or_null("FootDust") as CPUParticles2D
	if foot_dust:
		foot_dust.emitting = velocity.length() > 20.0

func _get_direction() -> Vector2:
	# Priority 1 — virtual joystick (Android)
	var joy : Control = get_meta("joystick_ref", null)
	if joy and (joy as Object).has_method("_input") and joy.output != Vector2.ZERO:
		return joy.output

	# Priority 2 — keyboard (WASD + arrows)
	var d := Vector2.ZERO
	if Input.is_key_pressed(KEY_W) or Input.is_key_pressed(KEY_UP):    d.y -= 1.0
	if Input.is_key_pressed(KEY_S) or Input.is_key_pressed(KEY_DOWN):  d.y += 1.0
	if Input.is_key_pressed(KEY_A) or Input.is_key_pressed(KEY_LEFT):  d.x -= 1.0
	if Input.is_key_pressed(KEY_D) or Input.is_key_pressed(KEY_RIGHT): d.x += 1.0
	return d.normalized() if d != Vector2.ZERO else Vector2.ZERO
