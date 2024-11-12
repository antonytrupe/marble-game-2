using Godot;
using Godot.Collections;
using System;
using System.Reflection;

public partial class Signals : Node
{
	[Signal]
	public delegate void PlayerZonedEventHandler(string player_id, string chunk_id);

	[Signal]
	public delegate void NewTurnEventHandler(int turn_id);

	[Signal]
	public delegate void ActionsEventHandler(int player_id, Dictionary actions);
}