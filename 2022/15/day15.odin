package template

import "core:c/libc"
import "core:fmt"
import "core:intrinsics"
import "core:math"
import "core:math/linalg"
import "core:mem"
import "core:os"
import "core:slice"
import "core:strconv"
import "core:strings"
import "core:time"

DAY :: 15

ANSWER_1: int
ANSWER_2: int

IS_EXAMPLE: bool
PROBLEM_DATA: []byte
EXAMPLE_DATA := `Sensor at x=2, y=18: closest beacon is at x=-2, y=15
Sensor at x=9, y=16: closest beacon is at x=10, y=16
Sensor at x=13, y=2: closest beacon is at x=15, y=3
Sensor at x=12, y=14: closest beacon is at x=10, y=16
Sensor at x=10, y=20: closest beacon is at x=10, y=16
Sensor at x=14, y=17: closest beacon is at x=10, y=16
Sensor at x=8, y=7: closest beacon is at x=2, y=10
Sensor at x=2, y=0: closest beacon is at x=2, y=10
Sensor at x=0, y=11: closest beacon is at x=2, y=10
Sensor at x=20, y=14: closest beacon is at x=25, y=17
Sensor at x=17, y=20: closest beacon is at x=21, y=22
Sensor at x=16, y=7: closest beacon is at x=15, y=3
Sensor at x=14, y=3: closest beacon is at x=15, y=3
Sensor at x=20, y=1: closest beacon is at x=15, y=3
`

puzzle :: proc() {
	IS_UNSIGNED :: intrinsics.type_is_unsigned
	IS_NUMERIC :: intrinsics.type_is_numeric
	ELEM_TYPE :: intrinsics.type_elem_type
	IS_ARRAY :: intrinsics.type_is_array
	sign :: proc(a: $T) -> (out: T) where IS_NUMERIC(ELEM_TYPE(T)) {
		when IS_ARRAY(T) {
			for i in 0 ..< len(T) {
				out[i] = sign(a[i])
			}
		} else when IS_UNSIGNED(T) {
			out = T(0 < a)
		} else {
			out = T(int(0 < a) - int(a < 0))
		}
		return
	}
	manhattan_distance :: proc(a, b: Point) -> int {
		d := linalg.abs(b - a)
		return d.x + d.y
	}

	Point :: [2]int
	Sensor :: struct{
		p, b: Point,
		d: int,
	}

	sensors: [dynamic]Sensor
	defer delete(sensors)

	iter := string(PROBLEM_DATA)
	for line in strings.split_lines_iterator(&iter) {
		if len(line) == 0 do continue
		input := strings.clone_to_cstring(line, context.temp_allocator)

		s: Sensor
		libc.sscanf(
			input,
			"Sensor at x=%jd, y=%jd: closest beacon is at x=%jd, y=%jd",
			&s.p.x, &s.p.y, &s.b.x, &s.b.y)
		s.d = manhattan_distance(s.p, s.b)
		append(&sensors, s)
	}

	get_spans :: proc(sensors: []Sensor, line: int, allocator := context.allocator) -> (spans: [dynamic]Point) {
		spans = make([dynamic]Point, allocator)
		for s in sensors {
			d_to_y := math.abs(s.p.y - line)
			if d_to_y <= s.d {
				remaining := s.d - d_to_y
				span := Point{s.p.x - remaining, s.p.x + remaining}
				append(&spans, span)
			}
		}
		slice.sort_by(spans[:], proc(a, b: Point) -> bool {
			return a.y < b.y
		})
		for i := len(spans) - 1; i > 0; i -= 1 {
			a, b := &spans[i], &spans[i - 1]
			if a.x <= b.y {
				b.x = min(a.x, b.x)
				b.y = max(a.y, b.y)
				unordered_remove(&spans, i)
			}
		}
		shrink(&spans)
		return
	}

	row_to_check := 10 if IS_EXAMPLE else 2_000_000
	spans := get_spans(sensors[:], row_to_check, context.temp_allocator)
	for s in spans {
		ANSWER_1 += math.abs(s.y - s.x)
	}

	// original extension of part 1 (avg time ~621ms)
	// for line in 0 ..< 4_000_000 {
	// 	spans := get_spans(sensors[:], line, context.temp_allocator)
	// 	if len(spans) > 1 {
	// 		ANSWER_2 = (spans[0].y + 1) * 4_000_000 + line
	// 	}
	// }

	// almost naive solution (~2.0s)
	// distress: for y := 0; y <= 4000000; y += 1 {
	// 	search: for x := 0; x <= 4000000; x += 1 {
	// 		for s in sensors {
	// 			d := manhattan_distance(s.p, {x, y})
	// 			if d <= s.d {
	// 				// this one line takes it from 16_000_000_000_000 comparisons to 174_640_068
	// 				x = s.p.x + (s.d - math.abs(s.p.y - y))
	// 				continue search
	// 			}
	// 		}
	// 		ANSWER_2 = x * 4000000 + y
	// 		break distress
	// 	}
	// }

	Intersection :: struct{ p: Point, ok: bool }
	line_intersection :: proc(l1, l2: [2]Point) -> Intersection {
		p1, p2, p3, p4 := l1.x, l1.y, l2.x, l2.y
		a := [2]f64{f64(p2.x - p1.x), f64(p2.y - p1.y)}
		b := [2]f64{f64(p3.x - p4.x), f64(p3.y - p4.y)}
		c := [2]f64{f64(p1.x - p3.x), f64(p1.y - p3.y)}

		d := b.x * a.y - a.x * b.y
		if d == 0 do return {{}, false}

		l12 := (c.x * b.y - b.x * c.y) / d
		if l12 < 0 || l12 > 1 do return {{}, false}

		l34 := (a.x * c.y - c.x * a.y) / d
		if l34 < 0 || l34 > 1 do return {{}, false}

		return {{p1.x + int(l12 * a.x), p1.y + int(l12 * a.y)}, true}
	}

	points: [dynamic]Point
	defer delete(points)
	for s1, i in sensors {
		for s2 in sensors[i + 1:] {
			// same beacon seems to not be needed
			if s1.b == s2.b {
				continue
			}

			sd := manhattan_distance(s1.p, s2.p)
			// too far away for any intersection tests
			if sd >= s1.d + s2.d + 1 {
				continue
			}
			// seems too close to be useful
			if sd <= s1.d || sd <= s2.d {
				continue
			}

			/*
			| 0, 1, 2, 3 -> top, right, bottom, left
			|     0         t
			|  -+ | ++   -+ | ++
			| 3---+---1 l---+---r
			|  -- | +-   -- | +-
			|     2         b
			*/
			s1d := s1.d + 1
			s1p := [4]Point{
				s1.p + {0, s1d}, // top
				s1.p + {s1d, 0}, // right
				s1.p - {0, s1d}, // bottom
				s1.p - {s1d, 0}, // left
			}
			s1l := [4][2]Point{
				{s1p[0], s1p[1]}, // ++ right top
				{s1p[1], s1p[2]}, // +- right bottom
				{s1p[2], s1p[3]}, // -- left bottom
				{s1p[3], s1p[0]}, // -+ left top
			}
			s2d := s2.d + 1
			s2p := [4]Point{
				s2.p + {0, s2d}, // top
				s2.p + {s2d, 0}, // right
				s2.p - {0, s2d}, // bottom
				s2.p - {s2d, 0}, // left
			}
			s2l := [4][2]Point{
				{s2p[0], s2p[1]}, // ++ right top
				{s2p[1], s2p[2]}, // +- right bottom
				{s2p[2], s2p[3]}, // -- left bottom
				{s2p[3], s2p[0]}, // -+ left top
			}

			sq := sign(s2.p - s1.p)
			is: [4]Intersection
			if sq.x > 0 {
				if sq.y > 0 {
					// ++
					is = {
						line_intersection(s1l[0], s2l[1]),
						line_intersection(s1l[0], s2l[3]),
						line_intersection(s1l[1], s2l[2]),
						line_intersection(s1l[3], s2l[2]),
					}
				} else
				if sq.y < 0 {
					// +-
					is = {
						line_intersection(s1l[1], s2l[0]),
						line_intersection(s1l[1], s2l[2]),
						line_intersection(s1l[0], s2l[3]),
						line_intersection(s1l[2], s2l[3]),
					}
				}
			} else
			if sq.x < 0 {
				if sq.y > 0 {
					// -+
					is = {
						line_intersection(s1l[3], s2l[0]),
						line_intersection(s1l[3], s2l[2]),
						line_intersection(s1l[0], s2l[1]),
						line_intersection(s1l[2], s2l[1]),
					}
				} else
				if sq.y < 0 {
					// --
					is = {
						line_intersection(s1l[2], s2l[1]),
						line_intersection(s1l[2], s2l[3]),
						line_intersection(s1l[1], s2l[0]),
						line_intersection(s1l[3], s2l[0]),
					}
				}
			}
			for i in is {
				if i.ok {
					append(&points, i.p)
				}
			}

			//math.floor_mod(i, 4)
		}
	}

	// now we can filter the results
	limit := 20 if IS_EXAMPLE else 4_000_000
	filter: for i := len(points) - 1; i >= 0; i -= 1 {
		p := points[i]
		if p.x < 0 || p.y < 0 || p.x > limit || p.y > limit {
			unordered_remove(&points, i)
			continue
		}
		for s in sensors {
			if manhattan_distance(s.p, p) <= s.d {
				unordered_remove(&points, i)
				continue filter
			}
		}
		if slice.count(points[:], p) > 1 {
			unordered_remove(&points, i)
		}
	}

	db := points[0]
	ANSWER_2 = db.x * 4_000_000 + db.y
}

/*
--- Day 15: Beacon Exclusion Zone ---

You feel the ground rumble again as the distress signal leads you to a large network of subterranean tunnels. You don't have time to search them all, but you don't need to: your pack contains a set of deployable sensors that you imagine were originally built to locate lost Elves.

The sensors aren't very powerful, but that's okay; your handheld device indicates that you're close enough to the source of the distress signal to use them. You pull the emergency sensor system out of your pack, hit the big button on top, and the sensors zoom off down the tunnels.

Once a sensor finds a spot it thinks will give it a good reading, it attaches itself to a hard surface and begins monitoring for the nearest signal source beacon. Sensors and beacons always exist at integer coordinates. Each sensor knows its own position and can determine the position of a beacon precisely; however, sensors can only lock on to the one beacon closest to the sensor as measured by the Manhattan distance. (There is never a tie where two beacons are the same distance to a sensor.)

It doesn't take long for the sensors to report back their positions and closest beacons (your puzzle input). For example:

Sensor at x=2, y=18: closest beacon is at x=-2, y=15
Sensor at x=9, y=16: closest beacon is at x=10, y=16
Sensor at x=13, y=2: closest beacon is at x=15, y=3
Sensor at x=12, y=14: closest beacon is at x=10, y=16
Sensor at x=10, y=20: closest beacon is at x=10, y=16
Sensor at x=14, y=17: closest beacon is at x=10, y=16
Sensor at x=8, y=7: closest beacon is at x=2, y=10
Sensor at x=2, y=0: closest beacon is at x=2, y=10
Sensor at x=0, y=11: closest beacon is at x=2, y=10
Sensor at x=20, y=14: closest beacon is at x=25, y=17
Sensor at x=17, y=20: closest beacon is at x=21, y=22
Sensor at x=16, y=7: closest beacon is at x=15, y=3
Sensor at x=14, y=3: closest beacon is at x=15, y=3
Sensor at x=20, y=1: closest beacon is at x=15, y=3

So, consider the sensor at 2,18; the closest beacon to it is at -2,15. For the sensor at 9,16, the closest beacon to it is at 10,16.

Drawing sensors as S and beacons as B, the above arrangement of sensors and beacons looks like this:

               1    1    2    2
     0    5    0    5    0    5
 0 ....S.......................
 1 ......................S.....
 2 ...............S............
 3 ................SB..........
 4 ............................
 5 ............................
 6 ............................
 7 ..........S.......S.........
 8 ............................
 9 ............................
10 ....B.......................
11 ..S.........................
12 ............................
13 ............................
14 ..............S.......S.....
15 B...........................
16 ...........SB...............
17 ................S..........B
18 ....S.......................
19 ............................
20 ............S......S........
21 ............................
22 .......................B....

This isn't necessarily a comprehensive map of all beacons in the area, though. Because each sensor only identifies its closest beacon, if a sensor detects a beacon, you know there are no other beacons that close or closer to that sensor. There could still be beacons that just happen to not be the closest beacon to any sensor. Consider the sensor at 8,7:

               1    1    2    2
     0    5    0    5    0    5
-2 ..........#.................
-1 .........###................
 0 ....S...#####...............
 1 .......#######........S.....
 2 ......#########S............
 3 .....###########SB..........
 4 ....#############...........
 5 ...###############..........
 6 ..#################.........
 7 .#########S#######S#........
 8 ..#################.........
 9 ...###############..........
10 ....B############...........
11 ..S..###########............
12 ......#########.............
13 .......#######..............
14 ........#####.S.......S.....
15 B........###................
16 ..........#SB...............
17 ................S..........B
18 ....S.......................
19 ............................
20 ............S......S........
21 ............................
22 .......................B....

This sensor's closest beacon is at 2,10, and so you know there are no beacons that close or closer (in any positions marked #).

None of the detected beacons seem to be producing the distress signal, so you'll need to work out where the distress beacon is by working out where it isn't. For now, keep things simple by counting the positions where a beacon cannot possibly be along just a single row.

So, suppose you have an arrangement of beacons and sensors like in the example above and, just in the row where y=10, you'd like to count the number of positions a beacon cannot possibly exist. The coverage from all sensors near that row looks like this:

                 1    1    2    2
       0    5    0    5    0    5
 9 ...#########################...
10 ..####B######################..
11 .###S#############.###########.

In this example, in the row where y=10, there are 26 positions where a beacon cannot be present.

Consult the report from the sensors you just deployed. In the row where y=2000000, how many positions cannot contain a beacon?

Your puzzle answer was 5181556.

--- Part Two ---

Your handheld device indicates that the distress signal is coming from a beacon nearby. The distress beacon is not detected by any sensor, but the distress beacon must have x and y coordinates each no lower than 0 and no larger than 4000000.

To isolate the distress beacon's signal, you need to determine its tuning frequency, which can be found by multiplying its x coordinate by 4000000 and then adding its y coordinate.

In the example above, the search space is smaller: instead, the x and y coordinates can each be at most 20. With this reduced search area, there is only a single position that could have a beacon: x=14, y=11. The tuning frequency for this distress beacon is 56000011.

Find the only possible position for the distress beacon. What is its tuning frequency?

Your puzzle answer was 12817603219131.
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
		IS_EXAMPLE = true
		PROBLEM_DATA = slice.clone(transmute([]byte) EXAMPLE_DATA)
	} else {
		IS_EXAMPLE = false
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
