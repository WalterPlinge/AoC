package day08

import "core:fmt"
import "core:math"
import "core:os"
import "core:slice"
import "core:strings"
import "core:time"

main :: proc() {
	start := time.now(); defer fmt.println("Time: ", time.diff(start, time.now()))

	fmt.println("Day", DAY)

	// Load the data
	when #config(example, false) {
		data := EXAMPLE_DATA
	} else {
		data, _ := os.read_entire_file(DAY_DATA); defer delete(data)
	}

	displays := strings.split(string(data), "\n"); defer delete(displays)

	{// Part 1
		fmt.println("\t1)", QUESTION_1)

		count := 0
		for dd, l in displays {
			in_out := strings.split(dd, "|"); defer delete(in_out)
			if len(in_out) < 2 {
				continue
			}
			output  := strings.fields(in_out[1]); defer delete(output)

			for f in output {
				switch len(f) {
					case 2, 3, 4, 7:
						count += 1
				}
			}
		}

		fmt.println("\t\ta)", count)
	}

	{// Part 2
		fmt.println("\t2)", QUESTION_2)

		// EIGHT :: "abcdefg" // length 7
		// ONE   :: "  c  f " // length 2
		// SEVEN :: "a c  f " // length 3
		// SIX   :: "ab defg" // length 6
		// FIVE  :: "ab d fg" // length 5
		// TWO   :: "a cde g" // length 5
		// THREE :: "a cd fg" // length 5
		// FOUR  :: " bcd f " // length 4
		// ZERO  :: "abc efg" // length 6
		// NINE  :: "abcd fg" // length 6

		/*
			(_1__4__78_)(_______) get 1, 4, 7, 8 from length
			(_1__4__78_)(A______) get A          from        7 against 1
			(_1__4_678_)(A_C__F_) get 6, C, F    from length 6 against 1       missing C
			(_12345678_)(A_C__F_) get 5, 2, 3    from length 5 against C, F
			(_12345678_)(ABC__F_) get B          from        4 against 3
			(_12345678_)(ABCD_F_) get D          from        4 against B, C, F
			(012345678_)(ABCD_F_) get 0          from length 6 against D
			(0123456789)(ABCDEF_) get 9, E       from length 6 against C, D, 8
			(0123456789)(ABCDEFG) get G          from        8 against A, B, C, D, E, F
		*/


		decrypt :: proc(input : []string) -> (translation : map[rune]rune) {
			zero, one, two, three, four, five, six, seven, eight, nine : string

			// (_1__4__78_)(_______) get 1, 4, 7, 8 from length
			for i in input {
				switch len(i) {
					case 2: one   = i
					case 4: four  = i
					case 3: seven = i
					case 7: eight = i
				}
			}

			// (_1__4__78_)(A______) get A from 7 against 1
			for c in seven {
				if strings.contains_rune(one, c) == -1 {
					translation['a'] = c
					break
				}
			}

			// (_1__4_678_)(A_C__F_) get 6, C, F from length 6 against 1 missing C
			one_c, one_f : rune = rune(one[0]), rune(one[1])
			one_loop: for c, r in one {
				for i in input {
					if  len(i) == 6 && strings.contains_rune(i, c) == -1 {
						six = i
						translation['c'] = c
						if c == one_f {
							one_c, one_f = one_f, one_c
						}
						break one_loop
					}
				}
			}
			translation['f'] = one_f

			// (_12345678_)(A_C__F_) get 5, 2, 3 from length 5 against C, F
			for i in input {
				if len(i) == 5 {
					if strings.contains_rune(i, translation['c']) == -1 {
						five = i
					} else if strings.contains_rune(i, translation['f']) == -1 {
						two = i
					} else {
						three = i
					}
				}
			}

			// (_12345678_)(ABC__F_) get B from 4 against 3
			for c in four {
				if strings.contains_rune(three, c) == -1 {
					translation['b'] = c
					break
				}
			}

			// (_12345678_)(ABCD_F_) get D from 4 against B, C, F
			for c in four {
				if c != translation['b'] && c != translation['c'] && c != translation['f'] {
					translation['d'] = c
					break
				}
			}

			// (012345678_)(ABCD_F_) get 0 from length 6 against D
			for i in input {
				if len(i) == 6 && strings.contains_rune(i, translation['d']) == -1 {
					zero = i
					break
				}
			}

			// (0123456789)(ABCDEF_) get 9, E from length 6 against C, D, 8
			for i in input {
				if len(i) == 6 \
				&& strings.contains_rune(i, translation['c']) != -1 \
				&& strings.contains_rune(i, translation['d']) != -1 {
					nine = i
					for c in eight {
						if strings.contains_rune(nine, c) == -1 {
							translation['e'] = c
							break
						}
					}
					break
				}
			}

			// (0123456789)(ABCDEFG) get G from 8 against A, B, C, D, E, F
			for c in eight {
				if c != translation['a'] \
				&& c != translation['b'] \
				&& c != translation['c'] \
				&& c != translation['d'] \
				&& c != translation['e'] \
				&& c != translation['f'] {
					translation['g'] = c
					break
				}
			}

			return translation
		}

		translate :: proc(s : string, translation : map[rune]rune) -> int {
			n := 0
			for c in s {
				switch c {
					case translation['a']: n += 1 << 0
					case translation['b']: n += 1 << 1
					case translation['c']: n += 1 << 2
					case translation['d']: n += 1 << 3
					case translation['e']: n += 1 << 4
					case translation['f']: n += 1 << 5
					case translation['g']: n += 1 << 6
				}
			}
			// 0b0_GFEDCBA
			digits := map[int]int {
				0b0_1110111 = 0, // "abc efg"
				0b0_0100100 = 1, // "  c  f "
				0b0_1011101 = 2, // "a cde g"
				0b0_1101101 = 3, // "a cd fg"
				0b0_0101110 = 4, // " bcd f "
				0b0_1101011 = 5, // "ab d fg"
				0b0_1111011 = 6, // "ab defg"
				0b0_0100101 = 7, // "a c  f "
				0b0_1111111 = 8, // "abcdefg"
				0b0_1101111 = 9, // "abcd fg"
			}
			return digits[n]
		}

		sum := 0
		for dd, l in displays {
			in_out := strings.split(dd, "|"); defer delete(in_out)
			if len(in_out) < 2 {
				continue
			}
			input  := strings.fields(in_out[0]); defer delete(input)
			output := strings.fields(in_out[1]); defer delete(output)

			translation := decrypt(input); defer delete(translation)

			// Put it all together
			value := 0
			for o, i in output {
				unit  := len(output) - i - 1
				digit := translate(o, translation)
				value += digit * int(math.pow(10, f64(unit)))
				//fmt.println(value)
			}
			//fmt.println(output)
			sum += value
		}

		fmt.println("\t\ta)", sum)
	}
}

DAY :: 8

QUESTION_1 :: "In the output values, how many times do digits 1, 4, 7, or 8 appear?"
QUESTION_2 :: "What do you get if you add up all of the output values?"

DAY_DATA :: "day08.txt"
EXAMPLE_DATA := \
`be cfbegad cbdgef fgaecd cgeb fdcge agebfd fecdb fabcd edb | fdgacbe cefdb cefbgd gcbe
edbfga begcd cbg gc gcadebf fbgde acbgfd abcde gfcbed gfec | fcgedb cgb dgebacf gc
fgaebd cg bdaec gdafb agbcfd gdcbef bgcad gfac gcb cdgabef | cg cg fdcagb cbg
fbegcd cbd adcefb dageb afcb bc aefdc ecdab fgdeca fcdbega | efabcd cedba gadfec cb
aecbfdg fbg gf bafeg dbefa fcge gcbea fcaegb dgceab fcbdga | gecf egdcabf bgf bfgea
fgeab ca afcebg bdacfeg cfaedg gcfdb baec bfadeg bafgc acf | gebdcfa ecba ca fadegcb
dbcfg fgd bdegcaf fgec aegbdf ecdfab fbedc dacgb gdcebf gf | cefg dcbef fcge gbcadfe
bdfegc cbegaf gecbf dfcage bdacg ed bedf ced adcbefg gebcd | ed bcgafe cdgba cbgef
egadfb cdbfeg cegd fecab cgb gbdefca cg fgcdab egfdb bfceg | gbdfcae bgc cg cgb
gcafb gcf dcaebfg ecagb gf abcdeg gaef cafbge fdbac fegbdc | fgae cfgab fg bagce`

/*

--- Day 8: Seven Segment Search ---

You barely reach the safety of the cave when the whale smashes into the cave mouth, collapsing it. Sensors indicate another exit to this cave at a much greater depth, so you have no choice but to press on.

As your submarine slowly makes its way through the cave system, you notice that the four-digit seven-segment displays in your submarine are malfunctioning; they must have been damaged during the escape. You'll be in a lot of trouble without them, so you'd better figure out what's wrong.

Each digit of a seven-segment display is rendered by turning on or off any of seven segments named a through g:

  0:      1:      2:      3:      4:
 aaaa    ....    aaaa    aaaa    ....
b    c  .    c  .    c  .    c  b    c
b    c  .    c  .    c  .    c  b    c
 ....    ....    dddd    dddd    dddd
e    f  .    f  e    .  .    f  .    f
e    f  .    f  e    .  .    f  .    f
 gggg    ....    gggg    gggg    ....

  5:      6:      7:      8:      9:
 aaaa    aaaa    aaaa    aaaa    aaaa
b    .  b    .  .    c  b    c  b    c
b    .  b    .  .    c  b    c  b    c
 dddd    dddd    ....    dddd    dddd
.    f  e    f  .    f  e    f  .    f
.    f  e    f  .    f  e    f  .    f
 gggg    gggg    ....    gggg    gggg

So, to render a 1, only segments c and f would be turned on; the rest would be off. To render a 7, only segments a, c, and f would be turned on.

The problem is that the signals which control the segments have been mixed up on each display. The submarine is still trying to display numbers by producing output on signal wires a through g, but those wires are connected to segments randomly. Worse, the wire/segment connections are mixed up separately for each four-digit display! (All of the digits within a display use the same connections, though.)

So, you might know that only signal wires b and g are turned on, but that doesn't mean segments b and g are turned on: the only digit that uses two segments is 1, so it must mean segments c and f are meant to be on. With just that information, you still can't tell which wire (b/g) goes to which segment (c/f). For that, you'll need to collect more information.

For each display, you watch the changing signals for a while, make a note of all ten unique signal patterns you see, and then write down a single four digit output value (your puzzle input). Using the signal patterns, you should be able to work out which pattern corresponds to which digit.

For example, here is what you might see in a single entry in your notes:

acedgfb cdfbe gcdfa fbcad dab cefabd cdfgeb eafb cagedb ab |
cdfeb fcadb cdfeb cdbaf

(The entry is wrapped here to two lines so it fits; in your notes, it will all be on a single line.)

Each entry consists of ten unique signal patterns, a | delimiter, and finally the four digit output value. Within an entry, the same wire/segment connections are used (but you don't know what the connections actually are). The unique signal patterns correspond to the ten different ways the submarine tries to render a digit using the current wire/segment connections. Because 7 is the only digit that uses three segments, dab in the above example means that to render a 7, signal lines d, a, and b are on. Because 4 is the only digit that uses four segments, eafb means that to render a 4, signal lines e, a, f, and b are on.

Using this information, you should be able to work out which combination of signal wires corresponds to each of the ten digits. Then, you can decode the four digit output value. Unfortunately, in the above example, all of the digits in the output value (cdfeb fcadb cdfeb cdbaf) use five segments and are more difficult to deduce.

For now, focus on the easy digits. Consider this larger example:

be cfbegad cbdgef fgaecd cgeb fdcge agebfd fecdb fabcd edb |
fdgacbe cefdb cefbgd gcbe
edbfga begcd cbg gc gcadebf fbgde acbgfd abcde gfcbed gfec |
fcgedb cgb dgebacf gc
fgaebd cg bdaec gdafb agbcfd gdcbef bgcad gfac gcb cdgabef |
cg cg fdcagb cbg
fbegcd cbd adcefb dageb afcb bc aefdc ecdab fgdeca fcdbega |
efabcd cedba gadfec cb
aecbfdg fbg gf bafeg dbefa fcge gcbea fcaegb dgceab fcbdga |
gecf egdcabf bgf bfgea
fgeab ca afcebg bdacfeg cfaedg gcfdb baec bfadeg bafgc acf |
gebdcfa ecba ca fadegcb
dbcfg fgd bdegcaf fgec aegbdf ecdfab fbedc dacgb gdcebf gf |
cefg dcbef fcge gbcadfe
bdfegc cbegaf gecbf dfcage bdacg ed bedf ced adcbefg gebcd |
ed bcgafe cdgba cbgef
egadfb cdbfeg cegd fecab cgb gbdefca cg fgcdab egfdb bfceg |
gbdfcae bgc cg cgb
gcafb gcf dcaebfg ecagb gf abcdeg gaef cafbge fdbac fegbdc |
fgae cfgab fg bagce

Because the digits 1, 4, 7, and 8 each use a unique number of segments, you should be able to tell which combinations of signals correspond to those digits. Counting only digits in the output values (the part after | on each line), in the above example, there are 26 instances of digits that use a unique number of segments (highlighted above).

In the output values, how many times do digits 1, 4, 7, or 8 appear?

--- Part Two ---

Through a little deduction, you should now be able to determine the remaining digits. Consider again the first example above:

acedgfb cdfbe gcdfa fbcad dab cefabd cdfgeb eafb cagedb ab |
cdfeb fcadb cdfeb cdbaf

After some careful analysis, the mapping between signal wires and segments only make sense in the following configuration:

 dddd
e    a
e    a
 ffff
g    b
g    b
 cccc

So, the unique signal patterns would correspond to the following digits:

    acedgfb: 8
    cdfbe: 5
    gcdfa: 2
    fbcad: 3
    dab: 7
    cefabd: 9
    cdfgeb: 6
    eafb: 4
    cagedb: 0
    ab: 1

Then, the four digits of the output value can be decoded:

    cdfeb: 5
    fcadb: 3
    cdfeb: 5
    cdbaf: 3

Therefore, the output value for this entry is 5353.

Following this same process for each entry in the second, larger example above, the output value of each entry can be determined:

    fdgacbe cefdb cefbgd gcbe: 8394
    fcgedb cgb dgebacf gc: 9781
    cg cg fdcagb cbg: 1197
    efabcd cedba gadfec cb: 9361
    gecf egdcabf bgf bfgea: 4873
    gebdcfa ecba ca fadegcb: 8418
    cefg dcbef fcge gbcadfe: 4548
    ed bcgafe cdgba cbgef: 1625
    gbdfcae bgc cg cgb: 8717
    fgae cfgab fg bagce: 4315

Adding all of the output values in this larger example produces 61229.

For each entry, determine all of the wire/segment connections and decode the four-digit output values. What do you get if you add up all of the output values?

*/
