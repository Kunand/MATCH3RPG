extends Node2D

var berry_type: int = 0
var berry_colors = [
	Color(1, 0, 0),    # Red
	Color(0, 1, 0),    # Green
	Color(0, 0, 1),    # Blue
	Color(1, 1, 0)     # Yellow
]

func _ready():
	update_appearance()

func set_type(type: int):
	berry_type = type
	update_appearance()

func update_appearance():
	# Get the sprite node
	var sprite = $Sprite2D
	
	# Create a new texture with the appropriate color
	var image = Image.create(64, 64, false, Image.FORMAT_RGBA8)
	image.fill(berry_colors[berry_type])
	
	# Create a new texture from the image
	var texture = ImageTexture.create_from_image(image)
	sprite.texture = texture
