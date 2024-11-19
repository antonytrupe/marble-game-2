class_name CustomMainLoop
extends SceneTree

var _input_thread: Thread


func _initialize() -> void:
	if DisplayServer.get_name() != "headless":
		return

	_input_thread = Thread.new()
	_input_thread.start(_listen_to_standard_input)


func _listen_to_standard_input() -> void:
	while true:
		prints("Insert some text:")
		var line := OS.read_string_from_stdin().strip_edges()
		prints("You inserted:", line)
		match line:
			"quit":
				prints("Quitting")
				_input_thread.wait_to_finish.call_deferred()
				quit.call_deferred()
				return
