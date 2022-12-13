package template

import "core:fmt"
import "core:math"
import "core:math/linalg"
import "core:mem"
import "core:os"
import "core:slice"
import "core:strconv"
import "core:strings"
import "core:time"

DAY :: 12

ANSWER_1: int
ANSWER_2: int

PROBLEM_DATA: []byte
EXAMPLE_DATA := `Sabqponm
abcryxxl
accszExk
acctuvwj
abdefghi
`

puzzle :: proc() {
	m := strings.split_lines(string(PROBLEM_DATA), context.temp_allocator)
	m = slice.filter(m, proc(s: string) -> bool { return len(s) > 0 })
	defer delete(m)

	hidth := len(m)
	width := len(m[0])

	start: [2]int
	end: [2]int
	for r, y in m {
		for c, x in r {
			if c == 'S' {
				start = {x, y}
			} else
			if c == 'E' {
				end = {x, y}
			}
		}
	}

	search :: proc(m: []string, start: [2]int, find: []int, inverse: bool) -> int {
		hidth := len(m)
		width := len(m[0])
		unvisited: [dynamic][2]int
		visited: [dynamic][2]int
		steps: map[[2]int]int
		defer {
			delete(unvisited)
			delete(visited)
			delete(steps)
		}
		append(&unvisited, start)
		steps[start] = 0
		for len(unvisited) > 0 {
			node: [2]int; {
				index: int
				step := max(int)
				for n, i in unvisited {
					s := steps[n]
					if s < step {
						node = n
						step = s
						index = i
					}
				}
				unordered_remove(&unvisited, index)
			}
			h1 := cast(int) m[node.y][node.x]
			if slice.contains(find, h1) do return steps[node]
			defer append(&visited, node)
			neighbours := make([dynamic][2]int, 0, 4, context.temp_allocator)
			if node.x > 0 do append(&neighbours, node - {1, 0})
			if node.y > 0 do append(&neighbours, node - {0, 1})
			if node.x < width - 1 do append(&neighbours, node + {1, 0})
			if node.y < hidth - 1 do append(&neighbours, node + {0, 1})
			for n in neighbours {
				if slice.contains(visited[:], n) do continue
				h1, h2 := cast(int) m[node.y][node.x], cast(int) m[n.y][n.x]
				if h1 == 'S' do h1 = 'a'
				if h1 == 'E' do h1 = 'z'
				if h2 == 'S' do h2 = 'a'
				if h2 == 'E' do h2 = 'z'
				if (!inverse && h2 > h1 + 1) || (inverse && h2 < h1 - 1) do continue
				s := steps[node] + 1
				if slice.contains(unvisited[:], n) {
					steps[n] = min(steps[n], s)
				} else {
					steps[n] = s
					append(&unvisited, n)
				}
			}
		}
		return -1
	}

	ANSWER_1 = search(m, start, {'E'}, false)
	ANSWER_2 = search(m, end, {'a', 'S'}, true)
}

/*
--- Day 12: Hill Climbing Algorithm ---

You try contacting the Elves using your handheld device, but the river you're following must be too low to get a decent signal.

You ask the device for a heightmap of the surrounding area (your puzzle input). The heightmap shows the local area from above broken into a grid; the elevation of each square of the grid is given by a single lowercase letter, where a is the lowest elevation, b is the next-lowest, and so on up to the highest elevation, z.

Also included on the heightmap are marks for your current position (S) and the location that should get the best signal (E). Your current position (S) has elevation a, and the location that should get the best signal (E) has elevation z.

You'd like to reach E, but to save energy, you should do it in as few steps as possible. During each step, you can move exactly one square up, down, left, or right. To avoid needing to get out your climbing gear, the elevation of the destination square can be at most one higher than the elevation of your current square; that is, if your current elevation is m, you could step to elevation n, but not to elevation o. (This also means that the elevation of the destination square can be much lower than the elevation of your current square.)

For example:

Sabqponm
abcryxxl
accszExk
acctuvwj
abdefghi

Here, you start in the top-left corner; your goal is near the middle. You could start by moving down or right, but eventually you'll need to head toward the e at the bottom. From there, you can spiral around to the goal:

v..v<<<<
>v.vv<<^
.>vv>E^^
..v>>>^^
..>>>>>^

In the above diagram, the symbols indicate whether the path exits each square moving up (^), down (v), left (<), or right (>). The location that should get the best signal is still E, and . marks unvisited squares.

This path reaches the goal in 31 steps, the fewest possible.

What is the fewest steps required to move from your current position to the location that should get the best signal?

Your puzzle answer was 420.

--- Part Two ---

As you walk up the hill, you suspect that the Elves will want to turn this into a hiking trail. The beginning isn't very scenic, though; perhaps you can find a better starting point.

To maximize exercise while hiking, the trail should start as low as possible: elevation a. The goal is still the square marked E. However, the trail should still be direct, taking the fewest steps to reach its goal. So, you'll need to find the shortest path from any square at elevation a to the square marked E.

Again consider the example from above:

Sabqponm
abcryxxl
accszExk
acctuvwj
abdefghi

Now, there are six choices for starting position (five marked a, plus the square marked S that counts as being at elevation a). If you start at the bottom-left square, you can reach the goal most quickly:

...v<<<<
...vv<<^
...v>E^^
.>v>>>^^
>^>>>>>^

This path reaches the goal in only 29 steps, the fewest possible.

What is the fewest steps required to move starting from any square with elevation a to the location that should get the best signal?

Your puzzle answer was 414.
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
	if slice.contains(os.args, "-example") {
		PROBLEM_DATA = slice.clone(transmute([]byte) EXAMPLE_DATA)
	} else {
		PROBLEM_DATA, _ = os.read_entire_file("input")
	}
	defer delete(PROBLEM_DATA)

	// puzzle
	fmt.println("Day", DAY)
	{
		start := time.now()
		puzzle()
		end := time.now()
		fmt.println("Time: ", time.diff(start, end))
	}
	fmt.println("\t1)", ANSWER_1)
	fmt.println("\t2)", ANSWER_2)

	// benchmark
	if slice.contains(os.args, "-benchmark") {
		iterations := 10
		start := time.now()
		for i in 0 ..< iterations {
			puzzle()
		}
		duration := time.diff(start, time.now())
		average := duration / time.Duration(iterations)
		fmt.println("Average time: ", average)
	}
}
