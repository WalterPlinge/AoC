package day01

import "core:fmt"
import "core:mem"
import "core:os"
import "core:time"

mem_tracked_main :: proc() {
	start := time.now(); defer fmt.println("Time: ", time.diff(start, time.now()))

	fmt.println("Day", DAY)

	// Load the data
	data : []byte; defer delete(data)
	switch #config(example, 0) {
		case 0: data, _ = os.read_entire_file(DAY_DATA)
		case 1: data = transmute([]byte) EXAMPLE_DATA
	}

	floor := 0
	basement := -1
	for d, i in data {
		floor += 1 if d == '(' else -1
		if basement == -1 && floor < 0 do basement = i + 1
	}

	// Part 1
	fmt.println("\t1)", QUESTION_1)
	fmt.println("\t\ta)", floor)

	// Part 2
	fmt.println("\t2)", QUESTION_2)
	fmt.println("\t\ta)", basement)
}

DAY :: 1

QUESTION_1 :: "To what floor do the instructions take Santa?"
QUESTION_2 :: "What is the position of the character that causes Santa to first enter the basement?"

DAY_DATA :: "day01.txt"
EXAMPLE_DATA := `()())`

/*

--- Day 1: Not Quite Lisp ---

Santa was hoping for a white Christmas, but his weather machine's "snow" function is powered by stars, and he's fresh out! To save Christmas, he needs you to collect fifty stars by December 25th.

Collect stars by helping Santa solve puzzles. Two puzzles will be made available on each day in the Advent calendar; the second puzzle is unlocked when you complete the first. Each puzzle grants one star. Good luck!

Here's an easy puzzle to warm you up.

Santa is trying to deliver presents in a large apartment building, but he can't find the right floor - the directions he got are a little confusing. He starts on the ground floor (floor 0) and then follows the instructions one character at a time.

An opening parenthesis, (, means he should go up one floor, and a closing parenthesis, ), means he should go down one floor.

The apartment building is very tall, and the basement is very deep; he will never find the top or bottom floors.

For example:

    (()) and ()() both result in floor 0.
    ((( and (()(()( both result in floor 3.
    ))((((( also results in floor 3.
    ()) and ))( both result in floor -1 (the first basement level).
    ))) and )())()) both result in floor -3.

To what floor do the instructions take Santa?

--- Part Two ---

Now, given the same instructions, find the position of the first character that causes him to enter the basement (floor -1). The first character in the instructions has position 1, the second character has position 2, and so on.

For example:

    ) causes him to enter the basement at character position 1.
    ()()) causes him to enter the basement at character position 5.

What is the position of the character that causes Santa to first enter the basement?

*/

main :: proc() {
	track : mem.Tracking_Allocator
	mem.tracking_allocator_init(&track, context.allocator)
	defer mem.tracking_allocator_destroy(&track)

	context.allocator = mem.tracking_allocator(&track)

	mem_tracked_main()

	if len(track.allocation_map) > 0 {
		fmt.println()
		for _, v in track.allocation_map {
			fmt.printf("%v - leaked %v bytes\n", v.location, v.size)
		}
	}
}
