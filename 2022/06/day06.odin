package template

import "core:fmt"
import "core:math"
import "core:mem"
import "core:os"
import "core:slice"
import "core:strconv"
import "core:strings"
import "core:time"

DAY :: 6

ANSWER_1: int
ANSWER_2: int

PROBLEM_DATA: []byte
EXAMPLE_DATA := `mjqjpqmgbljsphdztnvjfqwrcgsmlb`

puzzle :: proc() {
	// all my speed values are without compiler optimisations lol
	// i seem to get ~200us, ~73us, ~68us, ~61us
	// with -o:speed ~32.5us, ~8.5us, ~7.9us, ~6.2us

	// this is O(nm)
	search1 :: proc(d: []byte, n: int) -> int {
		for b in 0 ..< len(d) - n {
			m: bit_set[byte('a')..='z']
			for c in 0 ..< n do m |= {d[b + c]}
			if card(m) == n do return b + n
		}
		return 0
	}
	// this is O(n)
	search2 :: proc(data: []byte, n: int) -> int {
		freq: [256]int
		dup, dist: int
		for c1, i in data {
			freq[c1] += 1
			if freq[c1] > 1 do dup += 1
			if dist >= n {
				c2 := data[i - n]
				if freq[c2] > 1 do dup -= 1
				freq[c2] -= 1
			}
			dist += 1
			if dist >= n && dup == 0 do break
		}
		return dist
	}
	// i removed the `if dist >= n` branch
	search3 :: proc(data: []byte, n: int) -> int {
		freq: [256]int
		dup, dist: int
		dist = n
		for c, i in data[:n] {
			freq[c] += 1
			if freq[c] > 1 do dup += 1
		}
		for c1, i in data[n:] {
			c2 := data[i]
			freq[c1] += 1
			if freq[c1] > 1 do dup += 1
			if freq[c2] > 1 do dup -= 1
			freq[c2] -= 1
			dist += 1
			if dup == 0 do break
		}
		return dist
	}
	// i removed all branching and reordered `dup == 0`
	search4 :: proc(data: []byte, n: int) -> int {
		freq: [256]int
		dup, dist: int
		dist = n
		for c in data[:n] {
			freq[c] += 1
			dup += int(freq[c] > 1)
		}
		if dup == 0 do return dist
		for c1, i in data[n:] {
			c2 := data[i]
			freq[c1] += 1
			dup += int(freq[c1] > 1)
			dup -= int(freq[c2] > 1)
			if dup == 0 do return dist + 1
			freq[c2] -= 1
			dist += 1
		}
		return dist
	}
	ANSWER_1 = search4(PROBLEM_DATA, 4)
	ANSWER_2 = search4(PROBLEM_DATA, 14)
}

/*
--- Day 6: Tuning Trouble ---

The preparations are finally complete; you and the Elves leave camp on foot and begin to make your way toward the star fruit grove.

As you move through the dense undergrowth, one of the Elves gives you a handheld device. He says that it has many fancy features, but the most important one to set up right now is the communication system.

However, because he's heard you have significant experience dealing with signal-based systems, he convinced the other Elves that it would be okay to give you their one malfunctioning device - surely you'll have no problem fixing it.

As if inspired by comedic timing, the device emits a few colorful sparks.

To be able to communicate with the Elves, the device needs to lock on to their signal. The signal is a series of seemingly-random characters that the device receives one at a time.

To fix the communication system, you need to add a subroutine to the device that detects a start-of-packet marker in the datastream. In the protocol being used by the Elves, the start of a packet is indicated by a sequence of four characters that are all different.

The device will send your subroutine a datastream buffer (your puzzle input); your subroutine needs to identify the first position where the four most recently received characters were all different. Specifically, it needs to report the number of characters from the beginning of the buffer to the end of the first such four-character marker.

For example, suppose you receive the following datastream buffer:

mjqjpqmgbljsphdztnvjfqwrcgsmlb

After the first three characters (mjq) have been received, there haven't been enough characters received yet to find the marker. The first time a marker could occur is after the fourth character is received, making the most recent four characters mjqj. Because j is repeated, this isn't a marker.

The first time a marker appears is after the seventh character arrives. Once it does, the last four characters received are jpqm, which are all different. In this case, your subroutine should report the value 7, because the first start-of-packet marker is complete after 7 characters have been processed.

Here are a few more examples:

	bvwbjplbgvbhsrlpgdmjqwftvncz: first marker after character 5
	nppdvjthqldpwncqszvftbrmjlhg: first marker after character 6
	nznrnfrfntjfmvfwmzdfjlvtqnbhcprsg: first marker after character 10
	zcfzfwzzqfrljwzlrfnpqdbhtmscgvjw: first marker after character 11

How many characters need to be processed before the first start-of-packet marker is detected?

Your puzzle answer was 1794.

--- Part Two ---

Your device's communication system is correctly detecting packets, but still isn't working. It looks like it also needs to look for messages.

A start-of-message marker is just like a start-of-packet marker, except it consists of 14 distinct characters rather than 4.

Here are the first positions of start-of-message markers for all of the above examples:

	mjqjpqmgbljsphdztnvjfqwrcgsmlb: first marker after character 19
	bvwbjplbgvbhsrlpgdmjqwftvncz: first marker after character 23
	nppdvjthqldpwncqszvftbrmjlhg: first marker after character 23
	nznrnfrfntjfmvfwmzdfjlvtqnbhcprsg: first marker after character 29
	zcfzfwzzqfrljwzlrfnpqdbhtmscgvjw: first marker after character 26

How many characters need to be processed before the first start-of-message marker is detected?

Your puzzle answer was 2851.
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
		iterations := 1000
		start := time.now()
		for i in 0 ..< iterations {
			puzzle()
		}
		duration := time.diff(start, time.now())
		average := duration / time.Duration(iterations)
		fmt.println("Average time: ", average)
	}
}
