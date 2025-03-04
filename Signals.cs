using Godot;
using Godot.Collections;

public partial class Signals : Node
{
	[Signal]
	public delegate void PlayerZonedEventHandler(CharacterBody3D player, Node3D chunk);

	[Signal]
	public delegate void NewTurnEventHandler(int turn_id);

	[Signal]
	public delegate void ActionsEventHandler(int player_id, Dictionary actions);

	[Signal]
	public delegate void TimeWarpEventHandler(int minutes, Array<Node3D> chunks);

	[Signal]
	public delegate void CurrentPlayerEventHandler(CharacterBody3D player);

	[Signal]
	public delegate void WarpSpeedChangedEventHandler(float value);
}