package template


import "core:fmt"
import "core:math"
import "core:mem"
import "core:os"
import "core:slice"
import "core:strconv"
import "core:strings"
import "core:time"
import "core:unicode"

mem_tracked_main :: proc() {
	start := time.now(); defer fmt.println("Time: ", time.diff(start, time.now()))

	fmt.println("Day", DAY)

	// Load the data
	data : []byte; defer delete(data)
	switch #config(example, 0) {
		case 0: data, _ = os.read_entire_file(DAY_DATA)
		case 1: data = transmute([]byte) EXAMPLE_DATA_1
		case 2: data = transmute([]byte) EXAMPLE_DATA_2
		case 3: data = transmute([]byte) EXAMPLE_DATA_3
	}

	lines    := strings.fields(string(data)); defer delete(lines)
	cave_map :  map[string][dynamic]string; defer delete(cave_map)
	defer for k, v in cave_map do delete(v)
	for l in lines {
		path   := strings.split(l, "-"); defer delete(path)
		first  := path[0]
		second := path[1]
		if first not_in cave_map {
			cave_map[first] = make([dynamic]string)
		}
		if second not_in cave_map {
			cave_map[second] = make([dynamic]string)
		}
		append(&cave_map[first], second)
		append(&cave_map[second], first)
	}

	count_caves :: proc(cave_map : map[string][dynamic]string, yeah_ive_got_time : bool = false) -> int {
		Path :: struct{ double_visit : bool, caves : [dynamic]string }

		complete := make([dynamic]Path); defer delete(complete)
		defer for p in &complete do delete(p.caves)

		paths := make([dynamic]Path, 1); defer delete(paths)
		defer for p in &paths do delete(p.caves)
		paths[0].caves = make([dynamic]string, 1)
		paths[0].caves[0] = "start"

		for len(paths) > 0 {
			path      := pop(&paths); defer delete(path.caves)
			cave      := path.caves[len(path.caves) - 1]
			connected := cave_map[cave]
			for c in connected {
				double_visit := path.double_visit
				if c == "start" {
					continue
				}
				if unicode.is_lower(rune(c[0])) && slice.contains(path.caves[:], c) {
					if !yeah_ive_got_time || (yeah_ive_got_time && double_visit) {
						continue
					}
					double_visit = true
				}
				new_path             := Path{}
				new_path.double_visit = double_visit
				new_path.caves        = make([dynamic]string, len(path.caves) + 1)
				copy(new_path.caves[:], path.caves[:])
				new_path.caves[len(new_path.caves) - 1] = c
				if c == "end" {
					append(&complete, new_path)
				} else {
					append(&paths, new_path)
				}
			}
		}

		return len(complete)
	}

	// Part 1
	fmt.println("\t1)", QUESTION_1)
	fmt.println("\t\ta)", count_caves(cave_map))

	// Part 2
	fmt.println("\t2)", QUESTION_2)
	fmt.println("\t\ta)", count_caves(yeah_ive_got_time = true, cave_map = cave_map))
}

DAY :: 12

QUESTION_1 :: "How many paths through this cave system are there that visit small caves at most once?"
QUESTION_2 :: "Given these new rules, how many paths through this cave system are there?"

DAY_DATA :: "day12.txt"
EXAMPLE_DATA_1 := \
`start-A
start-b
A-c
A-b
b-d
A-end
b-end`
EXAMPLE_DATA_2 := \
`dc-end
HN-start
start-kj
dc-start
dc-HN
LN-dc
HN-end
kj-sa
kj-HN
kj-dc`
EXAMPLE_DATA_3 := \
`fs-end
he-DX
fs-he
start-DX
pj-DX
end-zg
zg-sl
zg-pj
pj-he
RW-he
fs-DX
pj-RW
zg-RW
start-pj
he-WI
zg-he
pj-fs
start-RW`

/*

--- Day 12: Passage Pathing ---

With your submarine's subterranean subsystems subsisting suboptimally, the only way you're getting out of this cave anytime soon is by finding a path yourself. Not just a path - the only way to know if you've found the best path is to find all of them.

Fortunately, the sensors are still mostly working, and so you build a rough map of the remaining caves (your puzzle input). For example:

start-A
start-b
A-c
A-b
b-d
A-end
b-end

This is a list of how all of the caves are connected. You start in the cave named start, and your destination is the cave named end. An entry like b-d means that cave b is connected to cave d - that is, you can move between them.

So, the above cave system looks roughly like this:

    start
    /   \
c--A-----b--d
    \   /
     end

Your goal is to find the number of distinct paths that start at start, end at end, and don't visit small caves more than once. There are two types of caves: big caves (written in uppercase, like A) and small caves (written in lowercase, like b). It would be a waste of time to visit any small cave more than once, but big caves are large enough that it might be worth visiting them multiple times. So, all paths you find should visit small caves at most once, and can visit big caves any number of times.

Given these rules, there are 10 paths through this example cave system:

start,A,b,A,c,A,end
start,A,b,A,end
start,A,b,end
start,A,c,A,b,A,end
start,A,c,A,b,end
start,A,c,A,end
start,A,end
start,b,A,c,A,end
start,b,A,end
start,b,end

(Each line in the above list corresponds to a single path; the caves visited by that path are listed in the order they are visited and separated by commas.)

Note that in this cave system, cave d is never visited by any path: to do so, cave b would need to be visited twice (once on the way to cave d and a second time when returning from cave d), and since cave b is small, this is not allowed.

Here is a slightly larger example:

dc-end
HN-start
start-kj
dc-start
dc-HN
LN-dc
HN-end
kj-sa
kj-HN
kj-dc

The 19 paths through it are as follows:

start,HN,dc,HN,end
start,HN,dc,HN,kj,HN,end
start,HN,dc,end
start,HN,dc,kj,HN,end
start,HN,end
start,HN,kj,HN,dc,HN,end
start,HN,kj,HN,dc,end
start,HN,kj,HN,end
start,HN,kj,dc,HN,end
start,HN,kj,dc,end
start,dc,HN,end
start,dc,HN,kj,HN,end
start,dc,end
start,dc,kj,HN,end
start,kj,HN,dc,HN,end
start,kj,HN,dc,end
start,kj,HN,end
start,kj,dc,HN,end
start,kj,dc,end

Finally, this even larger example has 226 paths through it:

fs-end
he-DX
fs-he
start-DX
pj-DX
end-zg
zg-sl
zg-pj
pj-he
RW-he
fs-DX
pj-RW
zg-RW
start-pj
he-WI
zg-he
pj-fs
start-RW

How many paths through this cave system are there that visit small caves at most once?

--- Part Two ---

After reviewing the available paths, you realize you might have time to visit a single small cave twice. Specifically, big caves can be visited any number of times, a single small cave can be visited at most twice, and the remaining small caves can be visited at most once. However, the caves named start and end can only be visited exactly once each: once you leave the start cave, you may not return to it, and once you reach the end cave, the path must end immediately.

Now, the 36 possible paths through the first example above are:

start,A,b,A,b,A,c,A,end
start,A,b,A,b,A,end
start,A,b,A,b,end
start,A,b,A,c,A,b,A,end
start,A,b,A,c,A,b,end
start,A,b,A,c,A,c,A,end
start,A,b,A,c,A,end
start,A,b,A,end
start,A,b,d,b,A,c,A,end
start,A,b,d,b,A,end
start,A,b,d,b,end
start,A,b,end
start,A,c,A,b,A,b,A,end
start,A,c,A,b,A,b,end
start,A,c,A,b,A,c,A,end
start,A,c,A,b,A,end
start,A,c,A,b,d,b,A,end
start,A,c,A,b,d,b,end
start,A,c,A,b,end
start,A,c,A,c,A,b,A,end
start,A,c,A,c,A,b,end
start,A,c,A,c,A,end
start,A,c,A,end
start,A,end
start,b,A,b,A,c,A,end
start,b,A,b,A,end
start,b,A,b,end
start,b,A,c,A,b,A,end
start,b,A,c,A,b,end
start,b,A,c,A,c,A,end
start,b,A,c,A,end
start,b,A,end
start,b,d,b,A,c,A,end
start,b,d,b,A,end
start,b,d,b,end
start,b,end

The slightly larger example above now has 103 paths through it, and the even larger example now has 3509 paths through it.

Given these new rules, how many paths through this cave system are there?

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
