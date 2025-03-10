extends GutTest


func test_1_second():
	var i= GameTime.get_age_parts(1000)
	assert_eq(i.years,0)
	assert_eq(i.months,0)
	assert_eq(i.days,0)
	assert_eq(i.hours,0)
	assert_eq(i.minutes,0)
	assert_eq(i.seconds,1)


func test_2_second():
	var i= GameTime.get_age_parts(2000)
	assert_eq(i.years,0)
	assert_eq(i.months,0)
	assert_eq(i.days,0)
	assert_eq(i.hours,0)
	assert_eq(i.minutes,0)
	assert_eq(i.seconds,2)

func test_2_and_a_half_second():
	var i= GameTime.get_age_parts(2500)
	assert_eq(i.years,0)
	assert_eq(i.months,0)
	assert_eq(i.days,0)
	assert_eq(i.hours,0)
	assert_eq(i.minutes,0)
	assert_eq(i.seconds,2)

func test_2_minutes_3_seconds():
	var i= GameTime.get_age_parts(123000)
	assert_eq(i.years,0)
	assert_eq(i.months,0)
	assert_eq(i.days,0)
	assert_eq(i.hours,0)
	assert_eq(i.minutes,2)
	assert_eq(i.seconds,3)

func test_360_days():
	var i= GameTime.get_age_parts(31104000000)
	assert_eq(i.years,1)
	assert_eq(i.months,0)
	assert_eq(i.days,0)
	assert_eq(i.hours,0)
	assert_eq(i.minutes,0)
	assert_eq(i.seconds,0)


func test_2_hours_3_minutes_4_seconds():
	var i= GameTime.get_age_parts(7384000)
	assert_eq(i.years,0)
	assert_eq(i.months,0)
	assert_eq(i.days,0)
	assert_eq(i.hours,2)
	assert_eq(i.minutes,3)
	assert_eq(i.seconds,4)
