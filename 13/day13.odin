package day_13

import "core:container"
import "core:fmt"
import la "core:math/linalg"
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
		case 1: data = transmute([]byte) EXAMPLE_DATA
	}

	tokens := strings.fields(string(data)); defer delete(tokens)

	Point :: [2]int
	Fold  :: struct{ axis : enum { X, Y }, value : int }

	points := make([dynamic]Point); defer delete(points)
	folds  := make([dynamic]Fold); defer delete(folds)

	for t in tokens {
		switch rune(t[0]) {
			case '0' .. '9':
				coords := strings.split(t, ","); defer delete(coords)
				append(&points, Point{ strconv.atoi(coords[0]), strconv.atoi(coords[1])})
			case 'x', 'y':
				fold  := strings.split(t, "="); defer delete(fold)
				append(&folds, Fold{ .X if fold[0] == "x" else .Y, strconv.atoi(fold[1]) })
		}
	}

	first_fold_count := 0
	for f, i in folds {
		for p := 0; p < len(points); p += 1 {
			new_point := points[p]
			switch f.axis {
				case .X: new_point.x = f.value - la.abs(f.value - points[p].x)
				case .Y: new_point.y = f.value - la.abs(f.value - points[p].y)
			}
			if points[p] != new_point && slice.contains(points[:], new_point) {
				unordered_remove(&points, p)
				p -= 1
			} else {
				points[p] = new_point
			}
		}
		if i == 0 {
			first_fold_count = len(points)
		}
	}

	slice.sort_by(points[:], proc(i, j : Point) -> bool {
		return i.y < j.y || (i.y == j.y && i.x < j.x)
	})
	minx, miny, maxx, maxy := max(int), max(int), min(int), min(int)
	for p in points {
		if p.x < minx do minx = p.x
		if p.y < miny do miny = p.y
		if p.x > maxx do maxx = p.x
		if p.y > maxy do maxy = p.y
	}
	code := strings.Builder{}; defer strings.destroy_builder(&code)
	current := 0
	for y in miny ..= maxy {
		strings.write_string(&code, "\n\t\t")
		for x in minx ..= maxx {
			if current < len(points) && points[current] == (Point{x, y}) {
				current += 1
				strings.write_string(&code, "#")
			} else {
				strings.write_string(&code, " ")
			}
		}
	}

	// Part 1
	fmt.println("\t1)", QUESTION_1)
	fmt.println("\t\ta)", first_fold_count)

	// Part 2
	fmt.println("\t2)", QUESTION_2)
	fmt.println("\t\ta)", strings.to_string(code))
}

DAY :: 13

QUESTION_1 :: "How many dots are visible after completing just the first fold instruction on your transparent paper?"
QUESTION_2 :: "What code do you use to activate the infrared thermal imaging camera system?"

DAY_DATA :: "day13.txt"
EXAMPLE_DATA := \
`6,10
0,14
9,10
0,3
10,4
4,11
6,0
6,12
4,1
0,13
10,12
3,4
3,0
8,4
1,10
2,14
8,10
9,0

fold along y=7
fold along x=5`

/*

--- Day 13: Transparent Origami ---

You reach another volcanically active part of the cave. It would be nice if you could do some kind of thermal imaging so you could tell ahead of time which caves are too hot to safely enter.

Fortunately, the submarine seems to be equipped with a thermal camera! When you activate it, you are greeted with:

Congratulations on your purchase! To activate this infrared thermal imaging
camera system, please enter the code found on page 1 of the manual.

Apparently, the Elves have never used this feature. To your surprise, you manage to find the manual; as you go to open it, page 1 falls out. It's a large sheet of transparent paper! The transparent paper is marked with random dots and includes instructions on how to fold it up (your puzzle input). For example:

6,10
0,14
9,10
0,3
10,4
4,11
6,0
6,12
4,1
0,13
10,12
3,4
3,0
8,4
1,10
2,14
8,10
9,0

fold along y=7
fold along x=5

The first section is a list of dots on the transparent paper. 0,0 represents the top-left coordinate. The first value, x, increases to the right. The second value, y, increases downward. So, the coordinate 3,0 is to the right of 0,0, and the coordinate 0,7 is below 0,0. The coordinates in this example form the following pattern, where # is a dot on the paper and . is an empty, unmarked position:

...#..#..#.
....#......
...........
#..........
...#....#.#
...........
...........
...........
...........
...........
.#....#.##.
....#......
......#...#
#..........
#.#........

Then, there is a list of fold instructions. Each instruction indicates a line on the transparent paper and wants you to fold the paper up (for horizontal y=... lines) or left (for vertical x=... lines). In this example, the first fold instruction is fold along y=7, which designates the line formed by all of the positions where y is 7 (marked here with -):

...#..#..#.
....#......
...........
#..........
...#....#.#
...........
...........
-----------
...........
...........
.#....#.##.
....#......
......#...#
#..........
#.#........

Because this is a horizontal line, fold the bottom half up. Some of the dots might end up overlapping after the fold is complete, but dots will never appear exactly on a fold line. The result of doing this fold looks like this:

#.##..#..#.
#...#......
......#...#
#...#......
.#.#..#.###
...........
...........

Now, only 17 dots are visible.

Notice, for example, the two dots in the bottom left corner before the transparent paper is folded; after the fold is complete, those dots appear in the top left corner (at 0,0 and 0,1). Because the paper is transparent, the dot just below them in the result (at 0,3) remains visible, as it can be seen through the transparent paper.

Also notice that some dots can end up overlapping; in this case, the dots merge together and become a single dot.

The second fold instruction is fold along x=5, which indicates this line:

#.##.|#..#.
#...#|.....
.....|#...#
#...#|.....
.#.#.|#.###
.....|.....
.....|.....

Because this is a vertical line, fold left:

#####
#...#
#...#
#...#
#####
.....
.....

The instructions made a square!

The transparent paper is pretty big, so for now, focus on just completing the first fold. After the first fold in the example above, 17 dots are visible - dots that end up overlapping after the fold is completed count as a single dot.

How many dots are visible after completing just the first fold instruction on your transparent paper?

--- Part Two ---

Finish folding the transparent paper according to the instructions. The manual says the code is always eight capital letters.

What code do you use to activate the infrared thermal imaging camera system?

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
