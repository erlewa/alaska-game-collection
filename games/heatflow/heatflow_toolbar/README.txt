How this toolbar works:
	- Tools are Button objects with an Icon and Theme
	- A ButtonGroup makes it so only one tool is selected at a time (subtle: *not* local to scene!)
	- Find the selected tool by checking toolbar_button_group.get_pressed_button().name

Written by Orion Lawlor, 2026-10-07 (with extensive design help from Gemini Thinking).
