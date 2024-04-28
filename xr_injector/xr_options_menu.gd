# This script is used as a hack to fix option buttons in VR in Godot. Unfortunately they hold onto focus with a death grip.
# So, if you move from one option button to another ultimately you are selecting the wrong option.
# This script connects to all option buttons and then registers their signals so that after an option is selected the parent quickly grabs focus and gives it back.

extends PanelContainer

func connect_option_button_chidren_signals():
	var option_button_children = find_children("*", "OptionButton", true, false)
	for option_button in option_button_children:
		option_button.connect("item_selected", Callable(self, "_on_option_button_option_selected"))
	
func _on_option_button_option_selected(option):
	focus_mode = Control.FOCUS_ALL
	grab_click_focus()
	focus_mode = Control.FOCUS_NONE
