extends Node

const PORT: int = 9999
var server: TCPServer
var connections: Array[StreamPeerTCP]
var listening: bool = false

func _ready():
	server = TCPServer.new()
	var r: Error = server.listen(9999)
	if r == Error.OK:
		listening = true
	else:
		listening = false


func _process(_delta):

	if !listening:
		return
	if connections.size():
		print("%s connections"%connections.size())

	if !server.is_listening():
		print('stopped listening')
	if server.is_connection_available():
		#print('connection_available')
		var connection: StreamPeerTCP = server.take_connection()
		connections.append(connection)

	for connection in connections:
		connection.poll()
		var status = connection.get_status()
		if status == StreamPeerTCP.STATUS_CONNECTED:
			#server.get
			print('STATUS_CONNECTED')

			# var r=connection.get_string(connection.get_available_bytes())
			#print('r:',r)

			var message: String = "OK"
			var content_length = message.length()

			var response = "HTTP/1.1 200 OK\r\n" + \
			"Access-Control-Expose-Headers: Content-Length\r\n" + \
			"Content-Length: %d\r\n" % content_length + \
			"Content-Type: text/plain\r\n\r\n%s" % message

			#print('response:',response)

			connection.put_data(response.to_ascii_buffer())
			connection.disconnect_from_host()

		elif status == StreamPeerTCP.STATUS_CONNECTING:
			print('STATUS_CONNECTING')
		elif status == StreamPeerTCP.STATUS_NONE:
			print('STATUS_NONE')
			connections.erase(connection)
		elif status == StreamPeerTCP.STATUS_ERROR:
			print('STATUS_ERROR')
			connections.erase(connection)
