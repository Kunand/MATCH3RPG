extends Node2D

var hp: int = 100
var max_hp: int = 100
var attack: int = 15
var character_type: int = 0  # 0: RED, 1: YELLOW, 2: BLUE, 3: GREEN
var is_player: bool = false

func _ready():
	# Initialize enemy stats based on type
	match character_type:
		0:  # RED
			hp = 100
			max_hp = 100
			attack = 20
			print("Enemy Red Warrior initialized - HP: ", hp, " Attack: ", attack)
		1:  # YELLOW
			hp = 80
			max_hp = 80
			attack = 25
			print("Enemy Yellow Mage initialized - HP: ", hp, " Attack: ", attack)
		2:  # BLUE
			hp = 120
			max_hp = 120
			attack = 15
			print("Enemy Blue Tank initialized - HP: ", hp, " Attack: ", attack)
		3:  # GREEN
			hp = 90
			max_hp = 90
			attack = 22
			print("Enemy Green Archer initialized - HP: ", hp, " Attack: ", attack)

func take_damage(amount: int):
	var old_hp = hp
	hp -= amount
	if hp < 0:
		hp = 0
	print("Enemy took ", amount, " damage!")
	print("HP: ", old_hp, " -> ", hp, " (", (hp * 100 / max_hp), "% remaining)")
	if hp == 0:
		print("Enemy has been defeated!")
	# TODO: Add visual feedback for damage

func is_alive() -> bool:
	return hp > 0

func get_attack_damage() -> int:
	print("Enemy preparing attack with power: ", attack)
	return attack 
