package template

import "core:fmt"
import "core:math"
import "core:mem"
import "core:os"
import "core:slice"
import "core:strconv"
import "core:strings"
import "core:time"

DAY :: 8

ANSWER_1: int
ANSWER_2: int

PROBLEM_DATA: []byte
EXAMPLE_DATA := `30373
25512
65332
33549
35390
`

puzzle :: proc() {
	lines := strings.split_lines(string(PROBLEM_DATA), context.temp_allocator)
	grid := slice.filter(lines, proc(s: string) -> bool { return len(s) > 0 })
	defer delete(grid)

	hidth := len(grid)
	width := len(grid[0])
	ANSWER_1 = 2 * (hidth + width - 2)

	for y in 1 ..< hidth - 1 {
		for x in 1 ..< width - 1 {
			tree := grid[y][x]
			o: [4]bool
			v: [4]int
			for t := x - 1; t >= 0; t -= 1 {
				v[0] += 1
				if grid[y][t] >= tree {
					o[0] = true
					break
				}
			}
			for t := x + 1; t < width; t += 1 {
				v[1] += 1
				if grid[y][t] >= tree {
					o[1] = true
					break
				}
			}
			for t := y - 1; t >= 0; t -= 1 {
				v[2] += 1
				if grid[t][x] >= tree {
					o[2] = true
					break
				}
			}
			for t := y + 1; t < hidth; t += 1 {
				v[3] += 1
				if grid[t][x] >= tree {
					o[3] = true
					break
				}
			}
			obscured := o[0] && o[1] && o[2] && o[3]
			visible := v[0] * v[1] * v[2] * v[3]
			if !obscured {
				ANSWER_1 += 1
			}
			if visible > ANSWER_2 {
				ANSWER_2 = visible
			}
		}
	}
}

/*
--- Day 8: Treetop Tree House ---

The expedition comes across a peculiar patch of tall trees all planted carefully in a grid. The Elves explain that a previous expedition planted these trees as a reforestation effort. Now, they're curious if this would be a good location for a tree house.

First, determine whether there is enough tree cover here to keep a tree house hidden. To do this, you need to count the number of trees that are visible from outside the grid when looking directly along a row or column.

The Elves have already launched a quadcopter to generate a map with the height of each tree (your puzzle input). For example:

30373
25512
65332
33549
35390

Each tree is represented as a single digit whose value is its height, where 0 is the shortest and 9 is the tallest.

A tree is visible if all of the other trees between it and an edge of the grid are shorter than it. Only consider trees in the same row or column; that is, only look up, down, left, or right from any given tree.

All of the trees around the edge of the grid are visible - since they are already on the edge, there are no trees to block the view. In this example, that only leaves the interior nine trees to consider:

	The top-left 5 is visible from the left and top. (It isn't visible from the right or bottom since other trees of height 5 are in the way.)
	The top-middle 5 is visible from the top and right.
	The top-right 1 is not visible from any direction; for it to be visible, there would need to only be trees of height 0 between it and an edge.
	The left-middle 5 is visible, but only from the right.
	The center 3 is not visible from any direction; for it to be visible, there would need to be only trees of at most height 2 between it and an edge.
	The right-middle 3 is visible from the right.
	In the bottom row, the middle 5 is visible, but the 3 and 4 are not.

With 16 trees visible on the edge and another 5 visible in the interior, a total of 21 trees are visible in this arrangement.

Consider your map; how many trees are visible from outside the grid?

Your puzzle answer was 1854.

--- Part Two ---

Content with the amount of tree cover available, the Elves just need to know the best spot to build their tree house: they would like to be able to see a lot of trees.

To measure the viewing distance from a given tree, look up, down, left, and right from that tree; stop if you reach an edge or at the first tree that is the same height or taller than the tree under consideration. (If a tree is right on the edge, at least one of its viewing distances will be zero.)

The Elves don't care about distant trees taller than those found by the rules above; the proposed tree house has large eaves to keep it dry, so they wouldn't be able to see higher than the tree house anyway.

In the example above, consider the middle 5 in the second row:

30373
25512
65332
33549
35390

	Looking up, its view is not blocked; it can see 1 tree (of height 3).
	Looking left, its view is blocked immediately; it can see only 1 tree (of height 5, right next to it).
	Looking right, its view is not blocked; it can see 2 trees.
	Looking down, its view is blocked eventually; it can see 2 trees (one of height 3, then the tree of height 5 that blocks its view).

A tree's scenic score is found by multiplying together its viewing distance in each of the four directions. For this tree, this is 4 (found by multiplying 1 * 1 * 2 * 2).

However, you can do even better: consider the tree of height 5 in the middle of the fourth row:

30373
25512
65332
33549
35390

	Looking up, its view is blocked at 2 trees (by another tree with a height of 5).
	Looking left, its view is not blocked; it can see 2 trees.
	Looking down, its view is also not blocked; it can see 1 tree.
	Looking right, its view is blocked at 2 trees (by a massive tree of height 9).

This tree's scenic score is 8 (2 * 2 * 1 * 2); this is the ideal spot for the tree house.

Consider each tree on your map. What is the highest scenic score possible for any tree?

Your puzzle answer was 527340.
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
