package day04

import "core:fmt"
import "core:mem"
import "core:os"
import "core:slice"
import "core:time"

import "core:crypto/md5"

DAY :: 4

ANSWER_1: int
ANSWER_2: int

PROBLEM_DATA: []byte
EXAMPLE_DATA := `abcdef`

puzzle :: proc() {
	for i := 0; i < int(max(i32)); i += 1 {
		key := fmt.tprintf("%s%i", string(PROBLEM_DATA), i)
		hash := md5.hash(key)
		out := fmt.tprintf("%2x", string(hash[:]))
		if string(out[:5]) == "00000" {
			ANSWER_1 = i
			break
		}
	}

	for i := ANSWER_1; i < int(max(i32)); i += 1 {
		key := fmt.tprintf("%s%i", string(PROBLEM_DATA), i)
		hash := md5.hash(key)
		out := fmt.tprintf("%2x", string(hash[:]))
		if string(out[:6]) == "000000" {
			ANSWER_2 = i
			break
		}
	}
}

/*
--- Day 4: The Ideal Stocking Stuffer ---

Santa needs help mining some AdventCoins
(very similar to bitcoins) to use as
gifts for all the economically forward-
thinking little girls and boys.

To do this, he needs to find MD5 hashes
which, in hexadecimal, start with at
least five zeroes. The input to the MD5
hash is some secret key (your puzzle
input, given below) followed by a number
in decimal. To mine AdventCoins, you must
find Santa the lowest positive number (no
leading zeroes: 1, 2, 3, ...) that
produces such a hash.

For example:

	If your secret key is abcdef, the
		answer is 609043, because the MD5
		hash of abcdef609043 starts with
		five zeroes (000001dbbfa...), and
		it is the lowest such number to
		do so.
	If your secret key is pqrstuv, the
		lowest number it combines with to
		make an MD5 hash starting with
		five zeroes is 1048970; that is,
		the MD5 hash of pqrstuv1048970
		looks like 000006136ef....

Your puzzle answer was 254575.

--- Part Two ---

Now find one that starts with six zeroes.

Your puzzle answer was 1038736.
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
