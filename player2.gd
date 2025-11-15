extends CharacterBody2D

# state related variables

enum States {IDLE, WALKING, RUNNING, JUMPING, FALLING, ROLLING, POUNDING}

var state = States.IDLE

var canWalk: bool
var canRun: bool
var canJump: bool
var canPound: bool
var canRoll: bool


# movement related variables

@export var speed = 300
@export var maxSpeed = 350
@export var jumpVelocity = -650
@export var jumpLimit = 1
@export var rollSpeed = 200
@export var rollDuration = 0.5

const GRAVITY = 1200
const MAX_GRAVITY = 1300
var dynamicGravity = GRAVITY
var jumpCount = 0

const COYOTE_TIME = 0.3
var coyoteTimer = COYOTE_TIME

@onready var sprite = $Sprite2D
@onready var jumpChecker: RayCast2D = $JumpCheck

func _physics_process(delta):
    var direction = Input.get_axis('LEFT', 'RIGHT')

    handleStates(delta)
    gravity(delta)
    movement(delta, direction)
    jump()
    groundPound()
    roll()

    move_and_slide()

func handleStates(delta):
    # landing
    if (is_on_floor() and state in [States.JUMPING, States.FALLING, States.POUNDING]):
        state = States.IDLE
        jumpCount = 0
        dynamicGravity = GRAVITY
        coyoteTimer = COYOTE_TIME

    # state permissions
    if (state == States.IDLE):
        print("IDLE")
        canWalk = true
        canRun = true
        canJump = true
        jumpCount = 0
        canRoll = true
        canPound = false
    elif (state == States.WALKING):
        print("WALKING")
        canWalk = true
        canRun = true
        canJump = true
        canRoll = true
        canPound = false
    elif (state == States.RUNNING):
        print("RUNNING")
        canWalk = false
        canRun = true
        canJump = true
        canRoll = true
        canPound = false
    elif (state == States.JUMPING):
        print("JUMPING")
        canWalk = true
        canRun = true
        canJump = false
        canRoll = true
        canPound = true
    elif (state == States.FALLING):
        print("FALLING")
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
        print("POUNDING")
        canWalk = false
        canRun = false
        canJump = false
        canRoll = true
        canPound = false
    elif (state == States.ROLLING):
        print("ROLLING")
        canWalk = false
        canRun = false
        canJump = false
        canRoll = false
        canPound = false

    # change to falling
    if (velocity.y > 0 and state not in [States.FALLING, States.POUNDING, States.ROLLING]):
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
            velocity.x = move_toward(velocity.x, direction * speed, maxSpeed * delta)
            sprite.flip_h = direction < 0
        else:
            if (state not in [States.JUMPING, States.FALLING]):
                state = States.IDLE
            # slow down
            velocity.x = move_toward(velocity.x, 0, maxSpeed * 2.5 * delta)

func jump():
    if (Input.is_action_just_pressed('JUMP')):
        if (canJump and jumpCount < jumpLimit):
            coyoteTimer = 0
            velocity.y = jumpVelocity
            jumpCount += 1
            state = States.JUMPING
    # cut jump short when button is released
    if (Input.is_action_just_released('JUMP') and velocity.y < 0):
        velocity.y = max(velocity.y, jumpVelocity * 0.4)

func groundPound():
    if (canPound and Input.is_action_just_pressed('DOWN')):
        state = States.POUNDING
        velocity.x = 0
        velocity.y = abs(jumpVelocity) * 2

func roll():
    if (canRoll):
        if (Input.is_action_just_pressed('ROLL')):
            if (state == States.POUNDING):
                velocity.y = 0

            state = States.ROLLING
            var roll_direction = -1 if sprite.flip_h else 1
            velocity.x += roll_direction * rollSpeed
            await get_tree().create_timer(rollDuration).timeout
            if (is_on_floor()):
                state = States.IDLE
            else:
                state = States.FALLING
