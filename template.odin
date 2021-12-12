package template


import "core:fmt"
import "core:math"
import "core:mem"
import "core:os"
import "core:slice"
import "core:strconv"
import "core:strings"
import "core:time"

mem_tracked_main :: proc() {
	start := time.now(); defer fmt.println("Time: ", time.diff(start, time.now()))

	fmt.println("Day", DAY)

	{ // Load the data
		when #config(example, false) {
			data := EXAMPLE_DATA
		} else {
			data, _ := os.read_entire_file(DAY_DATA); defer delete(data)
		}
	}

	{ // Part 1
		fmt.println("\t1)", QUESTION_1)

		fmt.println("\t\ta)")
	}

	{ // Part 2
		fmt.println("\t2)", QUESTION_2)

		fmt.println("\t\ta)")
	}
}

DAY :: 0

QUESTION_1 :: ""
QUESTION_2 :: ""

DAY_DATA :: "day.txt"
EXAMPLE_DATA := ``

/*

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
