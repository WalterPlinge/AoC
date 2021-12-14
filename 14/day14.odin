package day_14

import "core:fmt"
import "core:mem"
import "core:os"
import "core:strings"
import "core:time"

mem_tracked_main :: proc() {
	start := time.now(); defer fmt.println("Time: ", time.diff(start, time.now()))

	fmt.println("Day", DAY)

	// Load the data
	data : []byte; defer delete(data)
	switch #config(example, 0) {
		case 0: data, _ = os.read_entire_file(DAY_DATA)
		case 1: data = transmute([]byte) EXAMPLE_DATA
	}

	fields   := strings.fields(string(data)); defer delete(fields)
	template := fields[0]
	rules := make(map[string]rune, len(fields) / 3); defer delete(rules)
	for r := 1; r < len(fields); r += 3 {
		rules[fields[r]] = rune(fields[r + 2][0])
	}

	// gotta go fast
	Step_Pair :: struct{ step : int, pair : string }
	cache     :  map[Step_Pair]map[rune]int
	defer {
		for _, count_cache in cache {
			delete(count_cache)
		}
		delete(cache)
	}

	find_counts :: proc(
		template   : string,
		rules      : map[string]rune,
		step_count : int,
		cache      : ^map[Step_Pair]map[rune]int,
	) -> (counts : map[rune]int) {
		if step_count == 0 {
			return
		}

		for cpi := 0; cpi <= len(template) - 2; cpi += 1 {
			current_pair   := template[cpi:][:2]
			insert         := rules[current_pair]
			counts[insert] += 1

			key := Step_Pair{ step_count, current_pair }
			if count_cache, ok := cache[key]; ok {
				for r, c in count_cache {
					counts[r] += c
				}
				continue
			}

			expanded := []byte { current_pair[0], byte(insert), current_pair[1] }
			sub_counts := find_counts(string(expanded), rules, step_count - 1, cache)
			for r, c in sub_counts {
				counts[r] += c
			}

			cache[Step_Pair{ step_count, current_pair }] = sub_counts
		}

		return
	}

	min_max :: proc(m : map[rune]int) -> (int, int) {
		minf, maxf := max(int), min(int)
		for k, v in m {
			if v < minf do minf = v
			if v > maxf do maxf = v
		}
		return minf, maxf
	}

	common : map[rune]int; defer delete(common)
	common = find_counts(template, rules, 10, &cache)
	for t in template do common[t] += 1
	min1, max1 := min_max(common)

	delete(common)
	common = find_counts(template, rules, 40, &cache)
	for t in template do common[t] += 1
	min2, max2 := min_max(common)

	// Part 1
	fmt.println("\t1)", QUESTION_1)
	fmt.println("\t\ta)", max1 - min1)

	// Part 2
	fmt.println("\t2)", QUESTION_2)
	fmt.println("\t\ta)", max2 - min2)
}

DAY :: 14

QUESTION_1 :: "What is the result after 10 steps?"
QUESTION_2 :: "What is the result after 40 steps?"

DAY_DATA :: "day14.txt"
EXAMPLE_DATA := \
`NNCB

CH -> B
HH -> N
CB -> H
NH -> C
HB -> C
HC -> B
HN -> C
NN -> C
BH -> H
NC -> B
NB -> B
BN -> B
BB -> N
BC -> B
CC -> N
CN -> C`

/*

--- Day 14: Extended Polymerization ---

The incredible pressures at this depth are starting to put a strain on your submarine. The submarine has polymerization equipment that would produce suitable materials to reinforce the submarine, and the nearby volcanically-active caves should even have the necessary input elements in sufficient quantities.

The submarine manual contains instructions for finding the optimal polymer formula; specifically, it offers a polymer template and a list of pair insertion rules (your puzzle input). You just need to work out what polymer would result after repeating the pair insertion process a few times.

For example:

NNCB

CH -> B
HH -> N
CB -> H
NH -> C
HB -> C
HC -> B
HN -> C
NN -> C
BH -> H
NC -> B
NB -> B
BN -> B
BB -> N
BC -> B
CC -> N
CN -> C

The first line is the polymer template - this is the starting point of the process.

The following section defines the pair insertion rules. A rule like AB -> C means that when elements A and B are immediately adjacent, element C should be inserted between them. These insertions all happen simultaneously.

So, starting with the polymer template NNCB, the first step simultaneously considers all three pairs:

    The first pair (NN) matches the rule NN -> C, so element C is inserted between the first N and the second N.
    The second pair (NC) matches the rule NC -> B, so element B is inserted between the N and the C.
    The third pair (CB) matches the rule CB -> H, so element H is inserted between the C and the B.

Note that these pairs overlap: the second element of one pair is the first element of the next pair. Also, because all pairs are considered simultaneously, inserted elements are not considered to be part of a pair until the next step.

After the first step of this process, the polymer becomes NCNBCHB.

Here are the results of a few steps using the above rules:

Template:     NNCB
After step 1: NCNBCHB
After step 2: NBCCNBBBCBHCB
After step 3: NBBBCNCCNBBNBNBBCHBHHBCHB
After step 4: NBBNBNBBCCNBCNCCNBBNBBNBBBNBBNBBCBHCBHHNHCBBCBHCB

This polymer grows quickly. After step 5, it has length 97; After step 10, it has length 3073. After step 10, B occurs 1749 times, C occurs 298 times, H occurs 161 times, and N occurs 865 times; taking the quantity of the most common element (B, 1749) and subtracting the quantity of the least common element (H, 161) produces 1749 - 161 = 1588.

Apply 10 steps of pair insertion to the polymer template and find the most and least common elements in the result. What do you get if you take the quantity of the most common element and subtract the quantity of the least common element?

--- Part Two ---

The resulting polymer isn't nearly strong enough to reinforce the submarine. You'll need to run more steps of the pair insertion process; a total of 40 steps should do it.

In the above example, the most common element is B (occurring 2192039569602 times) and the least common element is H (occurring 3849876073 times); subtracting these produces 2188189693529.

Apply 40 steps of pair insertion to the polymer template and find the most and least common elements in the result. What do you get if you take the quantity of the most common element and subtract the quantity of the least common element?

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
