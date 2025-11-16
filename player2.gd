extends CharacterBody2D

# state related variables

enum States {IDLE, WALKING, WINDUP, RUNNING, JUMPING, FALLING, ROLLING, POUNDING}

var state = States.IDLE

var canWalk: bool
var canRun: bool
var canJump: bool
var canPound: bool
var canRoll: bool


# movement related variables

@export var speed = 300
const MAX_RUN_SPEED = 1000
var runSpeed = 350
@export var jumpVelocity = -650
@export var jumpLimit = 1
const BASE_ROLL_SPEED = 300
const ARIAL_ROLL_SPEED = 350
@export var rollSpeed = BASE_ROLL_SPEED
@export var rollDuration = 0.5

const GRAVITY = 1200
const MAX_GRAVITY = 1300
var dynamicGravity = GRAVITY
var jumpCount = 0

const COYOTE_TIME = 0.3
var coyoteTimer = COYOTE_TIME

@onready var sprite = $Sprite2D
@onready var jumpChecker: RayCast2D = $JumpCheck
@onready var wallChecker: RayCast2D = $WallCheck
@onready var animation: AnimationPlayer = $AnimationPlayer

var onWall = false
var pounded = false
var poundJumpCount = 0
var poundJumpLimit = 1

var rollQueued = false

func _ready():
	animation.play('player_idle')

func _physics_process(delta):
	var direction = Input.get_axis('LEFT', 'RIGHT')

	handleStates(delta)
	gravity(delta)
	movement(delta, direction)
	run(delta, direction)
	jump()
	groundPound()
	roll()

	if wallChecker.is_colliding():
		onWall = true
	else:
		onWall = false
	flipWallCheck()

	move_and_slide()

func handleStates(delta):
	# landing
	if (is_on_floor() and state in [States.JUMPING, States.FALLING, States.POUNDING, States.RUNNING]):
		if (state == States.POUNDING):
			await get_tree().create_timer(0.1).timeout

		state = States.IDLE if state != States.RUNNING else States.RUNNING
		jumpCount = 0
		dynamicGravity = GRAVITY
		coyoteTimer = COYOTE_TIME
		pounded = false
		poundJumpCount = 0

	# state permissions
	if (state == States.IDLE):
		#print("IDLE")
		animation.play('player_idle')

		canWalk = true
		canRun = true
		canJump = true
		jumpCount = 0
		canRoll = true
		canPound = false
	elif (state == States.WALKING):
		animation.play('player_walk')

		#print("WALKING")
		canWalk = true
		canRun = true
		canJump = true
		canRoll = true
		canPound = false
	elif (state == States.WINDUP):
		animation.play('player_run')
		print('windup')
	elif (state == States.RUNNING):
		#print("RUNNING")
		canWalk = false
		canRun = true
		canJump = true
		canRoll = true
		canPound = false
	elif (state == States.JUMPING):
		#print("JUMPING")
		animation.play('player_jump')

		canWalk = true
		canRun = true
		canJump = false
		canRoll = true
		canPound = true
	elif (state == States.FALLING):
		#print("FALLING")
		animation.play('player_fall')

		canWalk = true
		canRun = true
		if (coyoteTimer > 0):
			canJump = true
			coyoteTimer -= delta
		else:
			canJump = false
		canRoll = true
		canPound = true

		if jumpChecker.is_colliding():
			canJump = true
			jumpCount = 0
	elif (state == States.POUNDING):
		#print("POUNDING")
		animation.play('player_pound')

		canWalk = false
		canRun = false
		canJump = false
		canPound = false
		canRoll = true

		if jumpChecker.is_colliding():
			canJump = true
			jumpCount = 0
			canRoll = false
	elif (state == States.ROLLING):
		#print("ROLLING")
		canWalk = false
		canRun = false
		if (is_on_floor()):
			jumpCount = 0
			canJump = true
		else:
			canJump = false

		canRoll = false
		if (pounded):
			canPound = false
		else:
			canPound = true

	# change to falling
	if (velocity.y > 0 and state not in [States.FALLING, States.POUNDING, States.ROLLING, States.RUNNING]):
		state = States.FALLING

func gravity(delta):
	if (not is_on_floor()) and state not in [States.POUNDING]:
		velocity.y += dynamicGravity * delta

func movement(delta, direction):
	if (canWalk):
		if (direction != 0):
			if (state not in [States.JUMPING, States.FALLING]):
				state = States.WALKING
			# move in direction, flip sprite accordingly
			velocity.x = move_toward(velocity.x, direction * speed, speed * 1.15 * delta)
			sprite.flip_h = direction < 0
		else:
			if (state not in [States.JUMPING, States.FALLING]):
				state = States.IDLE
			# slow down
			velocity.x = move_toward(velocity.x, 0, speed * 1.15 * 2.5 * delta)

func run(delta, direction):
	var holdingButton = Input.is_action_pressed('RUN')
	if (canRun):
		if (state == States.IDLE):
			if (holdingButton):
				state = States.WINDUP
				runSpeed += MAX_RUN_SPEED / 2 * delta

				if (runSpeed >= MAX_RUN_SPEED and state == States.WINDUP):
					direction = 1 if not sprite.flip_h else -1
					runSpeed = MAX_RUN_SPEED
					state = States.RUNNING
		if (Input.is_action_just_released('RUN') and state == States.WINDUP):
			state = States.IDLE
			runSpeed = 350
		if (state == States.RUNNING):
			runSpeed = 350
			direction = 1 if not sprite.flip_h else -1
			velocity.x = MAX_RUN_SPEED * direction
			

func jump():
	if (Input.is_action_just_pressed('JUMP')):
		if ((canJump and jumpCount < jumpLimit) or (pounded and poundJumpCount 
		< poundJumpLimit and state == States.ROLLING)):
			coyoteTimer = 0
			velocity.y = jumpVelocity
			jumpCount += 1
			state = States.JUMPING if state != States.RUNNING else States.RUNNING

			if pounded:
				poundJumpCount += 1
	# cut jump short when button is released
	if (Input.is_action_just_released('JUMP') and velocity.y < 0):
		velocity.y = max(velocity.y, jumpVelocity * 0.4)

func groundPound():
	if (canPound and Input.is_action_just_pressed('DOWN')):
		pounded = true
		state = States.POUNDING
		velocity.x = 0
		velocity.y = abs(jumpVelocity) * 1.5

func roll():
	if (canRoll):
		if (Input.is_action_just_pressed('ROLL')):
			if (state == States.POUNDING):
				velocity.y = 0

			state = States.ROLLING

			animation.play('player_roll_start')

			if (is_on_floor()):
				rollSpeed = BASE_ROLL_SPEED
			else:
				rollSpeed = ARIAL_ROLL_SPEED

			var roll_direction = -1 if sprite.flip_h else 1
			velocity.x += roll_direction * rollSpeed
			await animation.animation_finished
			animation.play('player_roll')
			await get_tree().create_timer(rollDuration).timeout
			if (is_on_floor()):
				state = States.IDLE
				
			else:
				state = States.FALLING
			rollQueued = false

func flipWallCheck():
	if sprite.flip_h:
		wallChecker.position.x = -(wallChecker.position.x)
		wallChecker.scale.x = -(wallChecker.scale.x)
	else:
		wallChecker.position.x = abs(wallChecker.position.x)
		wallChecker.scale.x = abs(wallChecker.scale.x)
