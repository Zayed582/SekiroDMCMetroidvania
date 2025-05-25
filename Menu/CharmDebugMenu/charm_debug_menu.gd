extends CanvasLayer

func _ready():
	print("🟢 CharmDebugMenu is READY")
	call_deferred("_connect_all_buttons")

func _connect_all_buttons():
	var buttons = {
		"ButtonMomentumDrive": "Momentum Drive",
		"ButtonVengefulSpirit": "Vengeful Spirit",
		"ButtonBloodVoltage": "Blood Voltage",
		"ButtonAdrenalEdge": "Adrenal Edge",
		"ButtonComboCatalyst": "Combo Catalyst",
		"ButtonRazorBloom": "Razor Bloom",
		"ButtonDoubleEdgedSoul": "Double Edged Soul",
		"ButtonShockRepeater": "Shock Repeater",
		"ButtonGhostfangDrive": "Ghost Fang Drive",
		"ButtonOverdriveParryDistortion": "Parry Distortion Overdrive",
		"ButtonOverdriveCloneEcho": "Clone Echo Overdrive",
		"ButtonOverdriveMoonveilMirage": "Moonveil Mirage Overdrive",
		"ButtonOverdrivePhantomBlink": "Phantom Blink Overdrive",
		"ButtonOverdriveInfernalAscension": "Infernal Ascension Overdrive",

	}

	for node_name in buttons.keys():
		var button_path = "VBoxContainer/" + node_name
		if has_node(button_path):
			var button = get_node(button_path)
			button.pressed.connect(func(): _on_charm_button_pressed(buttons[node_name]))
			print("✅ Connected:", node_name)
		else:
			print("❌ Missing button:", node_name)

func _on_charm_button_pressed(charm_name: String):
	var player = get_node("/root/World/Player")
	if not player:
		print("❌ Player not found")
		return

	# Disable all charms
	player.active_charm_momentum_drive = false
	player.active_charm_vengeful_spirit = false
	player.active_charm_blood_voltage = false
	player.active_charm_adrenal_edge = false
	player.active_charm_combo_catalyst = false
	player.active_charm_razor_bloom = false
	player.active_charm_double_edged_soul = false
	player.active_charm_shock_repeater = false
	player.active_charm_ghostfang_drive = false
	

	# Disable all overdrives
	player.overdrive_type_parry_distortion = false
	player.overdrive_clone_echo = false
	player.overdrive_moonveil = false
	player.overdrive_phantom = false
	player.overdrive_infernal = false

	# Enable selected
	match charm_name:
		"Momentum Drive":
			player.active_charm_momentum_drive = true
		"Vengeful Spirit":
			player.active_charm_vengeful_spirit = true
		"Blood Voltage":
			player.active_charm_blood_voltage = true
		"Adrenal Edge":
			player.active_charm_adrenal_edge = true
		"Combo Catalyst":
			player.active_charm_combo_catalyst = true
		"Razor Bloom":
			player.active_charm_razor_bloom = true
		"Double Edged Soul":
			player.active_charm_double_edged_soul = true
		"Shock Repeater":
			player.active_charm_shock_repeater = true
		"Ghost Fang Drive":
			player.active_charm_ghostfang_drive = true
			player.ghostfang_tier = "SMOKIN STYLE"
		"Parry Distortion Overdrive":
			player.overdrive_type_parry_distortion = true
			player.selected_overdrive_type = "parry_distortion"
		"Clone Echo Overdrive":
			player.overdrive_clone_echo = true
			player.selected_overdrive_type = "clone_echo"
		"Moonveil Mirage Overdrive":
			player.overdrive_moonveil = true
			player.selected_overdrive_type = "moonveil"
		"Phantom Blink Overdrive":
			player.overdrive_phantom = true
			player.selected_overdrive_type = "phantom"
		"Infernal Ascension Overdrive":
			player.overdrive_infernal = true
			player.selected_overdrive_type = "infernal"


	print("✅ Active effect:", charm_name)
