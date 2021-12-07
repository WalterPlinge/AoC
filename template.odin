package template

import "core:fmt"
import "core:os"

main :: proc() {
	fmt.println("Day", DAY)

	{ // Load the data
		when #config(example, false) {
			data := EXAMPLE_DATA
		} else {
			data, _ := os.read_entire_file(DAY_DATA); defer delete(data)
		}
	}

	{ // Part 1
		fmt.println("\t1)", QUESTION_1)

		fmt.println("\t\ta)")
	}

	{ // Part 2
		fmt.println("\t2)", QUESTION_2)

		fmt.println("\t\ta)")
	}
}

DAY :: 0

QUESTION_1 :: ""
QUESTION_2 :: ""

DAY_DATA :: "day.txt"
EXAMPLE_DATA := ``

/*

*/
