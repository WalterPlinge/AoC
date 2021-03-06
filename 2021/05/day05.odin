package day05

import "core:fmt"
import "core:os"
import "core:strconv"
import "core:strings"
import "core:time"

main :: proc() {
	start := time.now(); defer fmt.println("Time: ", time.diff(start, time.now()))

	fmt.println("Day 5")

	Point :: [2]int
	Line  :: [2]Point

	vents : []Line; defer delete(vents)

	{ // Load the data
		when #config(example, false) {
			data := example_data
		} else {
			data, _ := os.read_entire_file("day05.txt"); defer delete(data)
		}

		point_strings := strings.fields(string(data)); defer delete(point_strings)
		// strings.fields split on whitespace, so every line has 3 tokens
		// ("a,b", "->", "c,d")
		vents = make([]Line, len(point_strings) / 3)

		for v, i in &vents {
			p1  := strings.split(point_strings[i * 3 + 0], ","); defer delete(p1)
			p2  := strings.split(point_strings[i * 3 + 2], ","); defer delete(p2)
			v[0] = Point{ strconv.atoi(p1[0]), strconv.atoi(p1[1]) }
			v[1] = Point{ strconv.atoi(p2[0]), strconv.atoi(p2[1]) }
		}
	}

	{ // Part 1
		fmt.println("\t1) Consider only horizontal and vertical lines. At how many points do at least two lines overlap?")

		pos : map[Point]int

		for v in vents {
			p1 := v[0]
			p2 := v[1]
			d  := Point{
				max(min(p2.x - p1.x, 1), -1),
				max(min(p2.y - p1.y, 1), -1),
			}

			if d.x != 0 && d.y != 0 {
				continue
			}

			for p := p1; p != p2 + d; p += d {
				pos[p] += 1
			}
		}

		count := 0
		for _, v in pos {
			if v >= 2 {
				count += 1
			}
		}

		fmt.println("\t\ta)",count)
	}

	{ // Part 2
		fmt.println("\t2) Consider all of the lines. At how many points do at least two lines overlap?")

		pos : map[Point]int

		for v in vents {
			p1 := v[0]
			p2 := v[1]
			d  := Point{
				max(min(p2.x - p1.x, 1), -1),
				max(min(p2.y - p1.y, 1), -1),
			}

			for p := p1; p != p2 + d; p += d {
				pos[p] += 1
			}
		}

		count := 0
		for _, v in pos {
			if v >= 2 {
				count += 1
			}
		}

		fmt.println("\t\ta)",count)
	}
}

example_data := \
`0,9 -> 5,9
8,0 -> 0,8
9,4 -> 3,4
2,2 -> 2,1
7,0 -> 7,4
6,4 -> 2,0
0,9 -> 2,9
3,4 -> 1,4
0,0 -> 8,8
5,5 -> 8,2`

/*

--- Day 5: Hydrothermal Venture ---

You come across a field of hydrothermal vents on the ocean floor! These vents constantly produce large, opaque clouds, so it would be best to avoid them if possible.

They tend to form in lines; the submarine helpfully produces a list of nearby lines of vents (your puzzle input) for you to review. For example:

0,9 -> 5,9
8,0 -> 0,8
9,4 -> 3,4
2,2 -> 2,1
7,0 -> 7,4
6,4 -> 2,0
0,9 -> 2,9
3,4 -> 1,4
0,0 -> 8,8
5,5 -> 8,2

Each line of vents is given as a line segment in the format x1,y1 -> x2,y2 where x1,y1 are the coordinates of one end the line segment and x2,y2 are the coordinates of the other end. These line segments include the points at both ends. In other words:

    An entry like 1,1 -> 1,3 covers points 1,1, 1,2, and 1,3.
    An entry like 9,7 -> 7,7 covers points 9,7, 8,7, and 7,7.

For now, only consider horizontal and vertical lines: lines where either x1 = x2 or y1 = y2.

So, the horizontal and vertical lines from the above list would produce the following diagram:

. . . . . . . 1 . .
. . 1 . . . . 1 . .
. . 1 . . . . 1 . .
. . . . . . . 1 . .
. 1 1 2 1 1 1 2 1 1
. . . . . . . . . .
. . . . . . . . . .
. . . . . . . . . .
. . . . . . . . . .
2 2 2 1 1 1 . . . .

In this diagram, the top left corner is 0,0 and the bottom right corner is 9,9. Each position is shown as the number of lines which cover that point or . if no line covers that point. The top-left pair of 1s, for example, comes from 2,2 -> 2,1; the very bottom row is formed by the overlapping lines 0,9 -> 5,9 and 0,9 -> 2,9.

To avoid the most dangerous areas, you need to determine the number of points where at least two lines overlap. In the above example, this is anywhere in the diagram with a 2 or larger - a total of 5 points.

Consider only horizontal and vertical lines. At how many points do at least two lines overlap?

--- Part Two ---

Unfortunately, considering only horizontal and vertical lines doesn't give you the full picture; you need to also consider diagonal lines.

Because of the limits of the hydrothermal vent mapping system, the lines in your list will only ever be horizontal, vertical, or a diagonal line at exactly 45 degrees. In other words:

    An entry like 1,1 -> 3,3 covers points 1,1, 2,2, and 3,3.
    An entry like 9,7 -> 7,9 covers points 9,7, 8,8, and 7,9.

Considering all lines from the above example would now produce the following diagram:

1 . 1 . . . . 1 1 .
. 1 1 1 . . . 2 . .
. . 2 . 1 . 1 1 1 .
. . . 1 . 2 . 2 . .
. 1 1 2 3 1 3 2 1 1
. . . 1 . 2 . . . .
. . 1 . . . 1 . . .
. 1 . . . . . 1 . .
1 . . . . . . . 1 .
2 2 2 1 1 1 . . . .

You still need to determine the number of points where at least two lines overlap. In the above example, this is still anywhere in the diagram with a 2 or larger - now a total of 12 points.

Consider all of the lines. At how many points do at least two lines overlap?

*/
