extends CharacterBody2D

enum States {IDLE, WALKING, RUNNING, JUMPING, FALLING, ROLLING, POUNDING}

var state = States.IDLE

@export var speed = 200
@export var maxSpeed = 300
@export var jumpVelocity = -700
@export var jumpLimit = 1
const GRAVITY = 1200
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

	var direction = Input.get_vector('LEFT', 'RIGHT', 'UP', 'DOWN')

	if (state == States.POUNDING):
		if (Input.is_action_just_pressed('ROLL')):
			roll()

	if (state != States.POUNDING):
		if (Input.is_action_just_pressed('ROLL')):
			roll()
		
		# apply gravity :)
		if (not is_on_floor()):
			canJump = false
			velocity.y += GRAVITY * delta

			if (velocity.y > 0):
				state = States.FALLING
		else:
			# landing
			canJump = true
			if (state == States.FALLING or state == States.JUMPING):
				jumpCount = 0
				if (direction == Vector2.ZERO):
					state = States.IDLE
				else:
					state = States.WALKING
		
		if (state != States.ROLLING):

			# jump

			if Input.is_action_just_pressed('JUMP'):
				jump()

			# doing actual movement

			if (direction != Vector2.ZERO):
				if (state != States.JUMPING and state != States.FALLING):
					state = States.WALKING
				velocity.x = direction.x * speed
			else:
				if (state != States.JUMPING and state != States.FALLING):
					state = States.IDLE
				velocity.x = 0
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
  # didn't add this yet
	pass
