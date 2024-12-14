using System;
using Godot;
using Godot.Collections;

public partial class JSON3D : Node
{
	public static JSON3D Instance { get; private set; }

	public override void _Ready()
	{
		Console.Write("JSON3d _ready");
		Instance = this;
	}

	public Vector2 DictionaryToVector2(Dictionary<string, float> d)
	{
		return new Vector2(d["x"], d["y"]);
	}

	public Dictionary Vector2ToDictionary(Vector2 vector2)
	{
		var d = new Dictionary
		{
			{"x",vector2.X},
			{"y",vector2.Y},
		};
		return d;
	}

	public Vector3 DictionaryToVector3(Dictionary<string, float> d)
	{
		return new Vector3(d["x"], d["y"], d["z"]);
	}

	public Dictionary Vector3ToDictionary(Vector3 vector3)
	{
		var d = new Dictionary
		{
			{"x",vector3.X},
			{"y",vector3.Y},
			{"z",vector3.Z}
		};
		return d;
	}

	public Dictionary Transform3DtoDictionary(Transform3D t)
	{
		var d = new Dictionary{
			{"basis",
			new Dictionary{
				{"x",Vector3ToDictionary(t.Basis.X)},
				{"y",Vector3ToDictionary(t.Basis.Y)},
				{"z",Vector3ToDictionary(t.Basis.Z)}
			}} ,
			 { "origin",Vector3ToDictionary(t.Origin)}
			};
		return d;
	}

	public Transform3D DictionaryToTransform3D(Dictionary<string, Variant> d)
	{
		var x_axis = DictionaryToVector3((Dictionary<string, float>)((Dictionary)d["basis"])["x"]);
		var y_axis = DictionaryToVector3((Dictionary<string, float>)((Dictionary)d["basis"])["y"]);
		var z_axis = DictionaryToVector3((Dictionary<string, float>)((Dictionary)d["basis"])["z"]);
		var origin = DictionaryToVector3((Dictionary<string, float>)d["origin"]);
		var _basis = new Basis(x_axis, y_axis, z_axis);

		return new Transform3D(_basis, origin);
	}


}