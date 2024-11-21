using Godot;
using Godot.Collections;

public partial class Signals : Node
{
	[Signal]
	public delegate void PlayerZonedEventHandler(CharacterBody3D player_id, Node3D chunk_id);

	[Signal]
	public delegate void NewTurnEventHandler(int turn_id);

	[Signal]
	public delegate void ActionsEventHandler(int player_id, Dictionary actions);

	[Signal]
	public delegate void TimeWarpEventHandler(int minutes, Array<Node3D> chunks);
}