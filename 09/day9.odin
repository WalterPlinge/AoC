package day_9

import "core:fmt"
import "core:math"
import "core:os"
import "core:slice"
import "core:strconv"
import "core:strings"
import "core:time"

main :: proc() {
	start := time.now(); defer fmt.println("Time: ", time.diff(start, time.now()))

	fmt.println("Day", DAY)

	heightmap : []i8; defer delete(heightmap)
	width, depth : int

	{ // Load the data
		when #config(example, false) {
			data := EXAMPLE_DATA
		} else {
			data, _ := os.read_entire_file(DAY_DATA); defer delete(data)
		}

		lines := strings.fields(string(data)); defer delete(lines)
		depth = len(lines)
		width  = len(lines[0])

		heightmap = make([]i8, width * depth)

		for l, y in lines {
			for c, x in l {
				heightmap[y * width + x] = i8(c - '0')
			}
		}
	}

	{ // Part 1
		fmt.println("\t1)", QUESTION_1)

		sum := 0
		for y in 0 ..< depth {
			for x in 0 ..< width {
				i := y * width + x
				v := heightmap[i]

				up    := i - width
				down  := i + width
				left  := i - 1
				right := i + 1

				is_low_point := \
					!(y >         0 && heightmap[up   ] <= v) &&
					!(y < depth - 1 && heightmap[down ] <= v) &&
					!(x >         0 && heightmap[left ] <= v) &&
					!(x < width - 1 && heightmap[right] <= v)

				if is_low_point {
					sum += int(v + 1)
				}
			}
		}

		fmt.println("\t\ta)", sum)
	}

	{ // Part 2
		fmt.println("\t2)", QUESTION_2)

		Point :: [2]int

		fill :: proc(
				low, point, dimensions : Point,
				heightmap : []i8,
				cache : ^map[Point]Point,
		) {
			i := point.y * dimensions.x + point.x
			v := heightmap[i]

			if v == 9 {
				return
			}

			if c, ok := cache[point]; ok {
				return
			}

			cache[point] = low

			has_up    := point.y > 0
			has_down  := point.y < dimensions.y - 1
			has_left  := point.x > 0
			has_right := point.x < dimensions.x - 1

			up    := i - dimensions.x
			down  := i + dimensions.x
			left  := i - 1
			right := i + 1

			if has_up && heightmap[up] >= v {
				fill(low, {point.x, point.y - 1}, dimensions, heightmap, cache)
			}
			if has_down && heightmap[down] >= v {
				fill(low, {point.x, point.y + 1}, dimensions, heightmap, cache)
			}
			if has_left && heightmap[left] >= v {
				fill(low, {point.x - 1, point.y}, dimensions, heightmap, cache)
			}
			if has_right && heightmap[right] >= v {
				fill(low, {point.x + 1, point.y}, dimensions, heightmap, cache)
			}
		}

		basins : map[Point]int; defer delete(basins)
		cache  : map[Point]Point; defer delete(cache)

		for y in 0 ..< depth {
			for x in 0 ..< width {
				i := y * width + x
				v := heightmap[i]

				has_up    := y > 0
				has_down  := y < depth - 1
				has_left  := x > 0
				has_right := x < width - 1

				up    := i - width
				down  := i + width
				left  := i - 1
				right := i + 1

				is_low_point := \
					!(has_up    && heightmap[up   ] <= v) &&
					!(has_down  && heightmap[down ] <= v) &&
					!(has_left  && heightmap[left ] <= v) &&
					!(has_right && heightmap[right] <= v)

				if is_low_point {
					low_point  := Point{x, y}
					dimensions := Point{width, depth}

					cache[low_point] = low_point

					if has_up {
						fill(low_point, {x, y - 1}, dimensions, heightmap, &cache)
					}
					if has_down {
						fill(low_point, {x, y + 1}, dimensions, heightmap, &cache)
					}
					if has_left {
						fill(low_point, {x - 1, y}, dimensions, heightmap, &cache)
					}
					if has_right {
						fill(low_point, {x + 1, y}, dimensions, heightmap, &cache)
					}
				}
			}
		}

		for _, v in cache {
			basins[v] += 1
		}

		Basin :: struct{ p : Point, c : int }
		sizes := make([dynamic]Basin); defer delete(sizes)
		reserve(&sizes, len(basins))
		for k, v in basins {
			append(&sizes, Basin{k, v})
		}
		slice.sort_by(sizes[:], proc(i, j : Basin) -> bool {
			return i.c > j.c
		})

		product := sizes[0].c * sizes[1].c * sizes[2].c

		fmt.println("\t\ta)", product)
	}
}

DAY :: 9

QUESTION_1 :: "What is the sum of the risk levels of all low points on your heightmap?"
QUESTION_2 :: "What do you get if you multiply together the sizes of the three largest basins?"

DAY_DATA :: "day9.txt"
EXAMPLE_DATA := `2199943210
3987894921
9856789892
8767896789
9899965678`

/*

--- Day 9: Smoke Basin ---

These caves seem to be lava tubes. Parts are even still volcanically active; small hydrothermal vents release smoke into the caves that slowly settles like rain.

If you can model how the smoke flows through the caves, you might be able to avoid it and be that much safer. The submarine generates a heightmap of the floor of the nearby caves for you (your puzzle input).

Smoke flows to the lowest point of the area it's in. For example, consider the following heightmap:

2199943210
3987894921
9856789892
8767896789
9899965678

Each number corresponds to the height of a particular location, where 9 is the highest and 0 is the lowest a location can be.

Your first goal is to find the low points - the locations that are lower than any of its adjacent locations. Most locations have four adjacent locations (up, down, left, and right); locations on the edge or corner of the map have three or two adjacent locations, respectively. (Diagonal locations do not count as adjacent.)

In the above example, there are four low points, all highlighted: two are in the first row (a 1 and a 0), one is in the third row (a 5), and one is in the bottom row (also a 5). All other locations on the heightmap have some lower adjacent location, and so are not low points.

The risk level of a low point is 1 plus its height. In the above example, the risk levels of the low points are 2, 1, 6, and 6. The sum of the risk levels of all low points in the heightmap is therefore 15.

Find all of the low points on your heightmap. What is the sum of the risk levels of all low points on your heightmap?

--- Part Two ---

Next, you need to find the largest basins so you know what areas are most important to avoid.

A basin is all locations that eventually flow downward to a single low point. Therefore, every low point has a basin, although some basins are very small. Locations of height 9 do not count as being in any basin, and all other locations will always be part of exactly one basin.

The size of a basin is the number of locations within the basin, including the low point. The example above has four basins.

The top-left basin, size 3:

2199943210
3987894921
9856789892
8767896789
9899965678

The top-right basin, size 9:

2199943210
3987894921
9856789892
8767896789
9899965678

The middle basin, size 14:

2199943210
3987894921
9856789892
8767896789
9899965678

The bottom-right basin, size 9:

2199943210
3987894921
9856789892
8767896789
9899965678

Find the three largest basins and multiply their sizes together. In the above example, this is 9 * 14 * 9 = 1134.

What do you get if you multiply together the sizes of the three largest basins?

*/
