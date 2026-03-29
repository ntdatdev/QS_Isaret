extends StaticBody2D
func disable_node(node: Node):
	# 1. Stop all processing (including children)
	node.process_mode = PROCESS_MODE_DISABLED
	
	# 2. Hide it (stops rendering and standard GUI input)
	if node is CanvasItem or node is Node3D:
		node.visible = false
	
	# 3. Disable input specifically
	node.set_process_input(false)
	node.set_process_unhandled_input(false)

func enable_node(node: Node):
	# 1. Resume processing (Inherit means it follows the parent's state)
	node.process_mode = PROCESS_MODE_INHERIT
	
	# 2. Show it again
	if node is CanvasItem or node is Node3D:
		node.visible = true
	
	# 3. Re-enable input
	node.set_process_input(true)
	node.set_process_unhandled_input(true)
