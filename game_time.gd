extends Node

#age in seconds
func get_age_parts(agems:float):
	return {
		"years": int(agems / (1000 * 60 * 60 * 24 * 30 * 12)),
		"months": int(agems / (1000 * 60 * 60 * 24 * 30)) % 12,
		"days": int(agems / (1000 * 60 * 60 * 24)) % 30,
		"hours": int(agems / (1000 * 60 * 60)) % 24,
		"minutes": int(agems / (1000 * 60)) % 60,
		"seconds": int(agems/ 1000)% 60,
	}


func format(agems):
	var age = get_age_parts(agems)
	return "%d years, %d months, %d days, %02d:%02d:%02d" % [age.years, age.months, age.days, age.hours, age.minutes, age.seconds]
