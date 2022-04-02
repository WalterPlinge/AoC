package day05

import "core:fmt"
import "core:mem"
import "core:os"
import "core:slice"
import "core:time"

import "core:strings"

DAY :: 5

ANSWER_1: int
ANSWER_2: int

PROBLEM_DATA: []byte
EXAMPLE_DATA := `ugknbfddgicrmopn
aaa
jchzalrnumimnmhp
haegwjzuvuyypxyu
dvszwmarrgswjxmb

qjhvhtzxzqqjkmpb
xxyxx
uurcxstgmygtbstg
ieodomkazucvgmuy`

puzzle :: proc() {
	is_nice :: proc(field: string) -> bool {
		vowels := 0
		double := false
		for c, i in transmute([]byte) field {
			if i + 1 < len(field) {
				switch field[i : i + 2] {
				case "ab", "cd", "pq", "xy":
					return false
				}
				if !double && c == field[i + 1] {
					double = true
				}
			}
			if vowels < 3 {
				switch c {
				case 'a', 'e', 'i', 'o', 'u':
					vowels += 1
				}
			}
		}
		return vowels >= 3 && double
	}

	field_iter := string(PROBLEM_DATA)
	for field in strings.fields_iterator(&field_iter) {
		if is_nice(field) {
			ANSWER_1 += 1
		}
	}

	is_nice_new :: proc(field: string) -> bool {
		repeat := false
		pair := false
		for c, i in transmute([]byte) field {
			if !repeat && i + 2 < len(field) {
				if c == field[i + 2] {
					repeat = true
				}
			}
			if !pair && i + 3 < len(field) {
				pair_loop: for j := i + 2; j + 1 < len(field); j += 1 {
					if field[i : i + 2] == field[j : j + 2] {
						pair = true
						break pair_loop
					}
				}
			}
		}
		return pair && repeat
	}

	field_iter = string(PROBLEM_DATA)
	for field in strings.fields_iterator(&field_iter) {
		if is_nice_new(field) {
			ANSWER_2 += 1
		}
	}
}

/*
--- Day 5: Doesn't He Have Intern-Elves For This? ---

Santa needs help figuring out which strings in his
text file are naughty or nice.

A nice string is one with all of the following
properties:

	It contains at least three vowels (aeiou only),
		like aei, xazegov, or aeiouaeiouaeiou.
	It contains at least one letter that appears
		twice in a row, like xx, abcdde (dd), or
		aabbccdd (aa, bb, cc, or dd).
	It does not contain the strings ab, cd, pq, or
		xy, even if they are part of one of the other
		requirements.

For example:

	ugknbfddgicrmopn is nice because it has at least
		three vowels (u...i...o...), a double letter
		(...dd...), and none of the disallowed
		substrings.
	aaa is nice because it has at least three vowels
		and a double letter, even though the letters
		used by different rules overlap.
	jchzalrnumimnmhp is naughty because it has no
		double letter.
	haegwjzuvuyypxyu is naughty because it contains
		the string xy.
	dvszwmarrgswjxmb is naughty because it contains
		only one vowel.

How many strings are nice?

Your puzzle answer was 236.

--- Part Two ---

Realizing the error of his ways, Santa has switched
to a better model of determining whether a string is
naughty or nice. None of the old rules apply, as they
are all clearly ridiculous.

Now, a nice string is one with all of the following
properties:

	It contains a pair of any two letters that
		appears at least twice in the string without
		overlapping, like xyxy (xy) or aabcdefgaa
		(aa), but not like aaa (aa, but it overlaps).
	It contains at least one letter which repeats
		with exactly one letter between them, like
		xyx, abcdefeghi (efe), or even aaa.

For example:

	qjhvhtzxzqqjkmpb is nice because is has a pair
		that appears twice (qj) and a letter that
		repeats with exactly one letter between them
		(zxz).
	xxyxx is nice because it has a pair that appears
		twice and a letter that repeats with one
		between, even though the letters used by each
		rule overlap.
	uurcxstgmygtbstg is naughty because it has a pair
		(tg) but no repeat with a single letter
		between them.
	ieodomkazucvgmuy is naughty because it has a
		repeating letter with one between (odo), but
		no pair that appears twice.

How many strings are nice under these new rules?

Your puzzle answer was 51.
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
		PROBLEM_DATA = transmute([]byte) EXAMPLE_DATA
	} else {
		PROBLEM_DATA, _ = os.read_entire_file("input")
	}
	defer if raw_data(PROBLEM_DATA) != raw_data(EXAMPLE_DATA) {
		delete(PROBLEM_DATA)
	}

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
