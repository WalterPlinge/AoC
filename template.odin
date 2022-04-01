package template

import "core:fmt"
import "core:mem"
import "core:os"
import "core:slice"
import "core:time"

DAY :: 0

ANSWER_1: int
ANSWER_2: int

PROBLEM_DATA: []byte
EXAMPLE_DATA := ``

puzzle :: proc() {

}

/*

*/

main :: proc() {
	// memory tracking
	track : mem.Tracking_Allocator
	mem.tracking_allocator_init(&track, context.allocator)
	defer mem.tracking_allocator_destroy(&track)
	context.allocator = mem.tracking_allocator(&track)
	defer if len(track.allocation_map) > 0 {
		fmt.println()
		for _, v in track.allocation_map {
			fmt.printf("%v - leaked %v bytes\n", v.location, v.size)
		}
	}

	// data loading
	defer if raw_data(PROBLEM_DATA) != raw_data(EXAMPLE_DATA) do delete(PROBLEM_DATA)
	if slice.contains(os.args, "-example") {
		PROBLEM_DATA = transmute([]byte) EXAMPLE_DATA
	} else {
		PROBLEM_DATA, _ = os.read_entire_file("input")
	}

	// puzzle
	fmt.println("Day", DAY)
	{
		start := time.now(); defer fmt.println("Time: ", time.diff(start, time.now()))
		puzzle()
	}
	fmt.println("\t1)", ANSWER_1)
	fmt.println("\t2)", ANSWER_2)

	// benchmark
	if slice.contains(os.args, "-benchmark") {
		iterations := 100
		start := time.now()
		for i in 0 ..< iterations {
			puzzle()
		}
		duration := time.diff(start, time.now())
		fmt.println("Average time: ", duration / time.Duration(iterations))
	}
}
