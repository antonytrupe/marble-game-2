extends Panel

const WARP_VOTE_SLOT_SCENE = preload("res://warp_vote_slot.tscn")

@export var me:MarbleCharacter
@export var game:Game
@onready var slots=%Votes


func _unhandled_input(event):
	game._unhandled_input(event)


func update():
	if not me:
		return
	var map:Dictionary={}

	#remove slots that need removed
	for child:WarpVoteSlot in slots.get_children():
		if child.warp_vote_id not in me.warp_votes:
			slots.remove_child(child)
			child.queue_free()
		else:
			map[child.warp_vote_id]=child

	# print(game.warp_votes)

	#add slots that need added
	for id in me.warp_votes:
		if id not in map.keys():
			var v:WarpVote=game.warp_votes.get_node_or_null(id)
			var s=WARP_VOTE_SLOT_SCENE.instantiate()
			s.warp_vote_id=id

			s.me=me
			slots.add_child(s)
			s.approved=v.players[me.player_id]
			#var chunks=me.get_chunks()
			#if chunks:
			s.display_name="%s minutes" % 60
