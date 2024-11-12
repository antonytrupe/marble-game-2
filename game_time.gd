extends Node


func get_age_parts(agems):
	return {
		"years": agems / (1000 * 60 * 60 * 24 * 30 * 360),
		"months": (agems / (1000 * 60 * 60 * 24 * 30)) % 360,
		"days": (agems / (1000 * 60 * 60 * 24)) % 30,
		"hours": (agems / (1000 * 60 * 60)) % 24,
		"minutes": (agems / (1000 * 60)) % 60,
		"seconds": (agems / 1000) % 60,
	}
