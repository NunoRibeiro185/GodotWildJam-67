extends OmniLight3D

const MAX_POS_Z = -183
const MIN_POS_Z = -249
const MIN_POS_X = 130

# Called when the node enters the scene tree for the first time.
func _ready():
	pass # Replace with function body.


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _physics_process(delta):
	position.z += 7 * delta
	position.x += 12 * delta
	
	if position.z > MAX_POS_Z:
		position.z = MIN_POS_Z
		position.x = MIN_POS_X
