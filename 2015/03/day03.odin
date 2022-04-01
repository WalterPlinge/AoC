package day03

import "core:fmt"
import "core:mem"
import "core:os"
import "core:slice"
import "core:time"

DAY :: 3

ANSWER_1: int
ANSWER_2: int

PROBLEM_DATA: []byte
EXAMPLE_DATA := `^v^v^v^v^v`

puzzle :: proc() {
	dir := [][2]int{
		'>' = { 1,  0},
		'<' = {-1,  0},
		'^' = { 0,  1},
		'v' = { 0, -1},
	}

	{
		pos := [2]int{}
		houses: map[[2]int]int; defer delete(houses)
		houses[pos] += 1
		for d in PROBLEM_DATA {
			pos += dir[d]
			houses[pos] += 1
		}
		ANSWER_1 = len(houses)
	}

	{
		pos := [2][2]int{}
		santa := 0
		houses: map[[2]int]int; defer delete(houses)
		houses[pos[santa]] += 1
		for d in PROBLEM_DATA {
			pos[santa] += dir[d]
			houses[pos[santa]] += 1
			santa = (santa + 1) % 2
		}
		ANSWER_2 = len(houses)
	}
}

/*
--- Day 3: Perfectly Spherical Houses in a Vacuum ---

Santa is delivering presents to an infinite
two-dimensional grid of houses.

He begins by delivering a present to the house at his
starting location, and then an elf at the North Pole
calls him via radio and tells him where to move next.
Moves are always exactly one house to the north (^),
south (v), east (>), or west (<). After each move, he
delivers another present to the house at his new
location.

However, the elf back at the north pole has had a
little too much eggnog, and so his directions are a
little off, and Santa ends up visiting some houses
more than once. How many houses receive at least one
present?

For example:

	> delivers presents to 2 houses: one at the
		starting location, and one to the east.
	^>v< delivers presents to 4 houses in a square,
		including twice to the house at his
		starting/ending location.
	^v^v^v^v^v delivers a bunch of presents to some
		very lucky children at only 2 houses.

Your puzzle answer was 2081.

--- Part Two ---

The next year, to speed up the process, Santa creates
a robot version of himself, Robo-Santa, to deliver
presents with him.

Santa and Robo-Santa start at the same location
(delivering two presents to the same starting house),
then take turns moving based on instructions from the
elf, who is eggnoggedly reading from the same script
as the previous year.

This year, how many houses receive at least one
present?

For example:

	^v delivers presents to 3 houses, because Santa
		goes north, and then Robo-Santa goes south.
	^>v< now delivers presents to 3 houses, and Santa
		and Robo-Santa end up back where they started.
	^v^v^v^v^v now delivers presents to 11 houses,
		with Santa going one direction and Robo-Santa
		going the other.

Your puzzle answer was 2341.
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
