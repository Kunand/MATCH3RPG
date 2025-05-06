extends Node2D

const GRID_SIZE := 6
const TILE_SIZE := 50
const TYPES := 4
const FALL_SPEED := 500.0

enum CharacterType {RED, YELLOW, BLUE, GREEN}

var character_stats = {
	CharacterType.RED: {"hp": 100, "attack": 20, "name": "Red Warrior"},
	CharacterType.YELLOW: {"hp": 80, "attack": 25, "name": "Yellow Mage"},
	CharacterType.BLUE: {"hp": 120, "attack": 15, "name": "Blue Tank"},
	CharacterType.GREEN: {"hp": 90, "attack": 22, "name": "Green Archer"}
}

var enemy_stats = {
	"hp": 500,
	"max_hp": 500,
	"attack": 30,
	"name": "Dark Dragon"
}

var berry_scene = preload("res://berry.tscn")
var board = []
var selected_chain := []
var is_animating := false
var player_attack_count := 0

var player_characters = []
var enemy = null

func _ready():
	print("Loading berry scene...")
	berry_scene = preload("res://berry.tscn")
	if berry_scene == null:
		print("ERROR: Failed to load berry scene!")
		return
		
	print("Berry scene loaded successfully")
	var board_node = $Board
	if board_node == null:
		print("ERROR: Board node not found!")
		return
		
	var screen_size = get_viewport_rect().size
	var board_width = GRID_SIZE * TILE_SIZE
	var board_height = GRID_SIZE * TILE_SIZE
	var board_x = (screen_size.x - board_width) / 2
	var board_y = screen_size.y - board_height - 10
	board_node.position = Vector2(board_x, board_y)
	
	initialize_characters()
	
	print("Initializing board...")
	for y in range(GRID_SIZE):
		var row = []
		for x in range(GRID_SIZE):
			var berry = create_berry(x, y)
			if berry != null:
				board_node.add_child(berry)
				berry.position = Vector2(x, y) * TILE_SIZE
				print("Added initial berry at position: ", berry.position)
			row.append(berry)
		board.append(row)
	print("Board initialization complete")

func initialize_characters():
	var screen_size = get_viewport_rect().size
	var character_spacing = 120
	var top_margin = 100
	
	for type in CharacterType.values():
		var character = create_character(type, true)
		if character:
			player_characters.append(character)
			add_child(character)
			character.position = Vector2(50 + (type * character_spacing), top_margin)
			print("Positioned player character ", character.get_meta("name"), " at ", character.position)
	
	enemy = Node2D.new()
	enemy.set_meta("hp", enemy_stats["hp"])
	enemy.set_meta("max_hp", enemy_stats["max_hp"])
	enemy.set_meta("attack", enemy_stats["attack"])
	enemy.set_meta("name", enemy_stats["name"])
	
	var enemy_rect = ColorRect.new()
	enemy_rect.size = Vector2(100, 100)
	enemy_rect.position = Vector2(-50, -50)
	enemy_rect.color = Color(0.5, 0, 0.5)
	enemy.add_child(enemy_rect)
	
	var enemy_hp_label = Label.new()
	enemy_hp_label.text = str(enemy_stats["hp"]) + "/" + str(enemy_stats["max_hp"])
	enemy_hp_label.position = Vector2(-50, -90)
	enemy_hp_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	enemy_hp_label.add_theme_color_override("font_color", Color.WHITE)
	enemy.add_child(enemy_hp_label)
	enemy.set_meta("hp_label", enemy_hp_label)
	
	var enemy_label = Label.new()
	enemy_label.text = enemy_stats["name"]
	enemy_label.position = Vector2(-50, -70)
	enemy_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	enemy_label.add_theme_color_override("font_color", Color.WHITE)
	enemy.add_child(enemy_label)
	
	add_child(enemy)
	enemy.position = Vector2(screen_size.x - 150, top_margin)
	print("Positioned enemy ", enemy.get_meta("name"), " at ", enemy.position)

func create_character(type: int, is_player: bool) -> Node2D:
	var character = Node2D.new()
	character.set_meta("type", type)
	character.set_meta("is_player", is_player)
	character.set_meta("hp", character_stats[type]["hp"])
	character.set_meta("max_hp", character_stats[type]["hp"])
	character.set_meta("attack", character_stats[type]["attack"])
	character.set_meta("name", character_stats[type]["name"])
	
	var color_rect = ColorRect.new()
	color_rect.size = Vector2(80, 80)
	color_rect.position = Vector2(-40, -40)
	
	match type:
		0:
			color_rect.color = Color(1, 0, 0)
		1:
			color_rect.color = Color(1, 1, 0)
		2:
			color_rect.color = Color(0, 0, 1)
		3:
			color_rect.color = Color(0, 1, 0)
	
	character.add_child(color_rect)
	
	var hp_label = Label.new()
	hp_label.text = str(character_stats[type]["hp"]) + "/" + str(character_stats[type]["hp"])
	hp_label.position = Vector2(-40, -80)
	hp_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	hp_label.add_theme_color_override("font_color", Color.WHITE)
	character.add_child(hp_label)
	character.set_meta("hp_label", hp_label)
	
	var label = Label.new()
	label.text = character_stats[type]["name"]
	label.position = Vector2(-40, -60)
	label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	label.add_theme_color_override("font_color", Color.WHITE)
	character.add_child(label)
	
	return character

func create_berry(x: int, y: int):
	if berry_scene == null:
		print("ERROR: Berry scene not loaded!")
		return null
		
	var berry = berry_scene.instantiate()
	if berry == null:
		print("ERROR: Failed to instantiate berry scene!")
		return null
		
	berry.set_type(randi() % TYPES)
	print("Created berry of type ", berry.berry_type, " for position ", Vector2(x, y))
	return berry

func _process(delta):
	if is_animating:
		var still_falling = false
		
		var target_positions = []
		for x in range(GRID_SIZE):
			var column_targets = []
			var empty_spaces = 0
			
			for y in range(GRID_SIZE):
				if board[y][x] == null:
					empty_spaces += 1
					column_targets.append(null)
				else:
					column_targets.append(Vector2(x, y - empty_spaces))
			target_positions.append(column_targets)
		
		for x in range(GRID_SIZE):
			for y in range(GRID_SIZE):
				var berry = board[y][x]
				if berry == null:
					continue
					
				var target_pos = target_positions[x][y]
				if target_pos != null and target_pos.y != y:
					still_falling = true
					var target_world_pos = target_pos * TILE_SIZE
					
					berry.position = berry.position.move_toward(target_world_pos, FALL_SPEED * delta)
					
					if berry.position.distance_to(target_world_pos) < 1:
						berry.position = target_world_pos
						board[y][x] = null
						board[target_pos.y][x] = berry
						print("Berry moved to position: ", target_pos)
		
		if not still_falling:
			print("Falling animation complete")
			is_animating = false
			
			var has_empty = false
			var empty_count = 0
			for x in range(GRID_SIZE):
				for y in range(GRID_SIZE):
					if board[y][x] == null:
						has_empty = true
						empty_count += 1
						print("Found empty space at: ", Vector2(x, y))
			
			print("Total empty spaces found: ", empty_count)
			if has_empty:
				print("Found empty spaces, generating new berries")
				generate_new_berries()
			else:
				print("No empty spaces found")

func _unhandled_input(event):
	if is_animating:
		return
		
	if event is InputEventMouseButton:
		if event.pressed and event.button_index == MOUSE_BUTTON_LEFT:
			selected_chain.clear()
			add_berry_under_mouse(event.position)
			print("Selected chain size: ", selected_chain.size())
		elif not event.pressed and event.button_index == MOUSE_BUTTON_LEFT:
			if selected_chain.size() >= 3:
				print("Removing ", selected_chain.size(), " berries")
				var chain_type = selected_chain[0].berry_type
				
				for berry in selected_chain:
					var grid_pos = berry.position / TILE_SIZE
					board[grid_pos.y][grid_pos.x] = null
					berry.queue_free()
				
				trigger_attack(chain_type, selected_chain.size())
				
				selected_chain.clear()
				is_animating = true
				print("Starting fall animation after removal")

	elif event is InputEventMouseMotion and Input.is_mouse_button_pressed(MOUSE_BUTTON_LEFT):
		add_berry_under_mouse(event.position)

func add_berry_under_mouse(pos):
	for y in range(GRID_SIZE):
		for x in range(GRID_SIZE):
			var berry = board[y][x]
			if berry == null or not is_instance_valid(berry):
				continue

			var dist = berry.global_position.distance_to(pos)

			if dist < TILE_SIZE / 3:
				if selected_chain.has(berry):
					if selected_chain.size() >= 2 and berry == selected_chain[-2]:
						selected_chain.pop_back()
						return
					return
				
				if selected_chain.size() == 0:
					selected_chain.append(berry)
					print("First berry added:", berry.berry_type)
					return
				
				var last = selected_chain[-1]
				if are_neighbors(berry, last) and berry.berry_type == last.berry_type:
					selected_chain.append(berry)
					print("Berry added to chain:", berry.berry_type)
					return

func are_neighbors(a, b):
	var delta = a.global_position - b.global_position
	var diagonal_distance = TILE_SIZE * 1.414
	return delta.length() <= diagonal_distance + 1

func generate_new_berries():
	print("Starting berry generation...")
	
	var column_empty_spaces = []
	for x in range(GRID_SIZE):
		var empty_count = 0
		for y in range(GRID_SIZE):
			if board[y][x] == null:
				empty_count += 1
		column_empty_spaces.append(empty_count)
		print("Column ", x, " has ", empty_count, " empty spaces")
	
	for x in range(GRID_SIZE):
		var empty_count = column_empty_spaces[x]
		if empty_count > 0:
			print("Generating ", empty_count, " berries for column ", x)
			
			var empty_positions = []
			for y in range(GRID_SIZE):
				if board[y][x] == null:
					empty_positions.append(y)
			
			for i in range(empty_count):
				var new_berry = create_berry(x, i)
				if new_berry == null:
					print("ERROR: Failed to create berry!")
					continue
					
				$Board.add_child(new_berry)
				print("Added berry to board node")
				
				var final_y = empty_positions[i]
				board[final_y][x] = new_berry
				new_berry.position = Vector2(x, final_y) * TILE_SIZE
				print("Placed berry at board position: ", Vector2(x, final_y))
	
	print("Berry generation complete")

func trigger_attack(berry_type: int, chain_size: int):
	var attacker = null
	for character in player_characters:
		if character.get_meta("type") == berry_type:
			attacker = character
			break
	
	if attacker and enemy:
		var base_damage = attacker.get_meta("attack")
		var damage = int(base_damage * (chain_size / 3.0))
		
		var current_hp = enemy.get_meta("hp")
		var max_hp = enemy.get_meta("max_hp")
		var new_hp = current_hp - damage
		enemy.set_meta("hp", new_hp)
		
		var enemy_hp_label = enemy.get_meta("hp_label")
		enemy_hp_label.text = str(new_hp) + "/" + str(max_hp)
		
		print("\n=== Combat Log ===")
		print("Attacker: ", attacker.get_meta("name"), " (Type: ", berry_type, ")")
		print("Target: ", enemy.get_meta("name"))
		print("\nPlayer Characters:")
		for char in player_characters:
			print("- ", char.get_meta("name"), ": HP ", char.get_meta("hp"), "/", char.get_meta("max_hp"), 
				" (", int((char.get_meta("hp") * 100.0 / char.get_meta("max_hp"))), "%)")
		
		print("\nEnemy:")
		print("- ", enemy.get_meta("name"), ": HP ", enemy.get_meta("hp"), "/", enemy.get_meta("max_hp"),
			" (", int((enemy.get_meta("hp") * 100.0 / enemy.get_meta("max_hp"))), "%)")
		
		print("\nAttack Details:")
		print(attacker.get_meta("name"), " attacks ", enemy.get_meta("name"), " for ", damage, " damage!")
		print(enemy.get_meta("name"), " HP: ", current_hp, " -> ", new_hp, " (", int((new_hp * 100.0 / max_hp)), "% remaining)")
		
		if new_hp <= 0:
			print(enemy.get_meta("name"), " has been defeated!")
		else:
			player_attack_count += 1
			
			if player_attack_count % 2 == 0:
				enemy_attack()
		
		print("================\n")

func enemy_attack():
	if not enemy:
		return
		
	var target = player_characters[randi() % player_characters.size()]
	var enemy_damage = enemy.get_meta("attack")
	var current_hp = target.get_meta("hp")
	var max_hp = target.get_meta("max_hp")
	var new_hp = current_hp - enemy_damage
	target.set_meta("hp", new_hp)
	
	var hp_label = target.get_meta("hp_label")
	hp_label.text = str(new_hp) + "/" + str(max_hp)
	
	print("\n=== Enemy Attack ===")
	print(enemy.get_meta("name"), " attacks ", target.get_meta("name"), " for ", enemy_damage, " damage!")
	print(target.get_meta("name"), " HP: ", current_hp, " -> ", new_hp, " (", int((new_hp * 100.0 / max_hp)), "% remaining)")
	
	if new_hp <= 0:
		print(target.get_meta("name"), " has been defeated!")
	print("================\n")
