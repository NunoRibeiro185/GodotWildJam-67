extends SubViewport

@onready var label = $Label as Label

# Called when the node enters the scene tree for the first time.
func _ready():
	size = label.get_rect().size

