extends CharacterBody2D

enum States {IDLE, WALKING, RUNNING, JUMPING, FALLING, ROLLING, POUNDING}

var state = States.IDLE

@export var speed = 300
@export var maxSpeed = 350
var jumpVelocity = -700
@export var jumpLimit = 1
const GRAVITY = 1200
const MAX_GRAVITY = 1300
var dynamicGravity = GRAVITY
var jumpCount = 0 
var canJump = true

func _physics_process(delta):
	# pounding

	if (Input.is_action_just_pressed('DOWN') and not is_on_floor()):
		state = States.POUNDING
		velocity.y = 1000
		velocity.x = 0
	if (state == States.POUNDING and is_on_floor()):
		# landing
		jumpCount = 0
		state = States.IDLE

	var direction = Input.get_axis('LEFT', 'RIGHT')

	if (state == States.POUNDING):
		if (Input.is_action_just_pressed('ROLL')):
			roll()

	if (state != States.POUNDING):
		if (Input.is_action_just_pressed('ROLL') and state != States.ROLLING):
			roll()
		
		# apply gravity :)
		if (not is_on_floor()):
			canJump = false
			if (dynamicGravity < MAX_GRAVITY):
				dynamicGravity = MAX_GRAVITY

			velocity.y += dynamicGravity * delta

			if (velocity.y > 0):
				dynamicGravity *= 1.05
				state = States.FALLING
		else:
			# landing
			canJump = true
			dynamicGravity = GRAVITY
			if (state == States.FALLING or state == States.JUMPING):
				jumpCount = 0
				if (direction == 0):
					state = States.IDLE
				else:
					state = States.WALKING
		
		if (state != States.ROLLING):

			# jump

			if Input.is_action_just_pressed('JUMP'):
				jump()
			if Input.is_action_just_released('JUMP') and velocity.y < 0:
				velocity.y = max(velocity.y, jumpVelocity * 0.4)

			# doing actual movement

			if (direction != 0):
				if (state != States.JUMPING and state != States.FALLING):
					state = States.WALKING
				velocity.x = move_toward(velocity.x, direction * speed, maxSpeed * delta)

				$Sprite2D.flip_h = direction < 0
			else:
				if (state != States.JUMPING and state != States.FALLING):
					state = States.IDLE
				velocity.x = move_toward(velocity.x, 0, maxSpeed * 2.5 * delta)
	# this needs to be here for everything to work xd

	move_and_slide()

func _process(delta):
	print(str(state))

func jump():
	if (jumpCount < jumpLimit and canJump):
		jumpCount += 1
		state = States.JUMPING
		velocity.y = jumpVelocity

func roll():
	print('hey this will do something')
	velocity.x = 0
	velocity.x += 200 if isRight() else -200
	state = States.ROLLING
	await get_tree().create_timer(0.5, false, false, true).timeout
	state = States.IDLE

func isRight():
	return not $Sprite2D.flip_h
