package template

import "core:c/libc"
import "core:container"
import "core:crypto/md5"
import "core:encoding/json"
import "core:fmt"
import "core:intrinsics"
import "core:math"
import "core:math/bits"
import "core:math/linalg"
import "core:mem"
import "core:os"
import "core:slice"
import "core:strconv"
import "core:strings"
import "core:time"
import "core:unicode"

DAY :: 0

ANSWER_1: string
ANSWER_2: string

puzzle :: proc() {

}

IS_EXAMPLE: bool
PROBLEM_DATA: []byte
EXAMPLE_DATA := ``

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
	IS_EXAMPLE = slice.contains(os.args, "-example")
	if IS_EXAMPLE {
		PROBLEM_DATA = slice.clone(transmute([]byte) EXAMPLE_DATA)
	} else {
		PROBLEM_DATA, _ = os.read_entire_file("input")
	}
	defer {
		delete(PROBLEM_DATA)
		delete(ANSWER_1)
		delete(ANSWER_2)
	}

	// puzzle
	fmt.println("Day", DAY)
	{
		start := time.now()
		puzzle()
		end := time.now()
		fmt.println("Time:", time.diff(start, end))
	}
	fmt.println("\t1)\n", ANSWER_1)
	fmt.println("\t2)\n", ANSWER_2)

	// benchmark
	if slice.contains(os.args, "-benchmark") {
		iterations := 10
		start := time.now()
		for i in 0 ..< iterations {
			delete(ANSWER_1)
			delete(ANSWER_2)
			puzzle()
		}
		duration := time.diff(start, time.now())
		average := duration / time.Duration(iterations)
		fmt.println("Average time: ", average)
	}
}
