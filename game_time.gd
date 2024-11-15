extends Node


func get_age_parts(agems:int):
	return {
		"years": agems / (1000 * 60 * 60 * 24 * 30 * 360),
		"months": (agems / (1000 * 60 * 60 * 24 * 30)) % 360,
		"days": (agems / (1000 * 60 * 60 * 24)) % 30,
		"hours": (agems / (1000 * 60 * 60)) % 24,
		"minutes": (agems / (1000 * 60)) % 60,
		"seconds": (agems / 1000) % 60,
	}


func format(agems):
	var age = get_age_parts(agems)
	return "%d years, %d months, %d days, %02d:%02d:%02d" % [age.years, age.months, age.days, age.hours, age.minutes, age.seconds]
