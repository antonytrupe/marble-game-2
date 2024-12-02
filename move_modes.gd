extends Node

enum MODE {
	##half the walk distance
	##usually 15ft/round
	CROUCH = 1,
	##single move action
	##usually 30ft/round
	WALK = 2,
	##this is the double move action
	##usually 60ft/round
	HUSTLE = 4,
	##not used?
	RUN = 6,
}

const STRINGS = {
	MODE.CROUCH: "CROUCH",
	MODE.WALK: "WALK",
	MODE.HUSTLE: "HUSTLE",
	MODE.RUN: "RUN",
}
