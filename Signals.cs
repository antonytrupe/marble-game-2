using Godot;
using System;

public partial class Signals : Node
{
	[Signal]
	public delegate void PlayerZonedEventHandler(string player_id, string chunk_id);

}