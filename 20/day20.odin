package day_20

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

	enhance := data[:512]

	data_rows := strings.fields(string(data[512:])); defer delete(data_rows)
	depth := len(data_rows)
	width := len(data_rows[0])

	enhance_image :: proc(enhance : []byte, old_image, new_image : ^[dynamic]byte, old_depth, old_width, new_depth, new_width, background : int) {
		for y in 0 ..< new_depth {
			for x in 0 ..< new_width {
				new_i := y * new_width + x

				number   : uint = 0
				number_i : uint = 8

				// convert current x, y relative to the old image (offset of 1)
				old_y := y - 1
				old_x := x - 1
				for j in old_y - 1 ..= old_y + 1 {
					for i in old_x - 1 ..= old_x + 1 {
						old_i := j * old_width + i
						if i >= 0 && i < old_width && j >= 0 && j < old_depth {
							number |= uint(old_image[old_i]) << uint(number_i)
						} else {
							number |= uint(background) << uint(number_i)
						}
						number_i -= 1
					}
				}

				new_image[new_i] = 1 if enhance[number] == '#' else 0
			}
		}
	}

	old_depth := depth
	old_width := width
	old_image := make([dynamic]byte, old_depth * old_width); defer delete(old_image)
	for r, y in data_rows do for c, x in r do old_image[y * width + x] = 1 if c == '#' else 0

	new_depth := old_depth + 2
	new_width := old_width + 2
	new_image := make([dynamic]byte, new_depth * new_width); defer delete(new_image)

	lit_pixels_1 := 0
	lit_pixels_2 := 0

	for i in 1 ..= 50 {
		// toggle the background if a 0 background will flip the infinite to 1
		background := (i - 1) % 2 if enhance[0] == '#' else 0

		enhance_image(enhance, &old_image, &new_image, old_depth, old_width, new_depth, new_width, background)

		// just swap the images
		old_image, new_image = new_image, old_image
		old_depth, old_width = new_depth, new_width
		new_depth += 2
		new_width += 2
		resize(&new_image, new_depth * new_width)

		if i == 2  do for p in old_image do lit_pixels_1 += int(p)
		if i == 50 do for p in old_image do lit_pixels_2 += int(p)
	}

	// Part 1
	fmt.println("\t1)", QUESTION_1)
	fmt.println("\t\ta)", lit_pixels_1)

	// Part 2
	fmt.println("\t2)", QUESTION_2)
	fmt.println("\t\ta)", lit_pixels_2)
}

DAY :: 20

QUESTION_1 :: "After 2 iterations, how many pixels are lit in the resulting image?"
QUESTION_2 :: "After 50 iterations, how many pixels are lit in the resulting image?"

DAY_DATA :: "day20.txt"
EXAMPLE_DATA := \
`..#.#..#####.#.#.#.###.##.....###.##.#..###.####..#####..#....#..#..##..###..######.###...####..#..#####..##..#.#####...##.#.#..#.##..#.#......#.###.######.###.####...#.##.##..#..#..#####.....#.#....###..#.##......#.....#..#..#..##..#...##.######.####.####.#.#...#.......#..#.#.#...####.##.#......#..#...##.#.##..#...##.#.##..###.#......#.#.......#.#.#.####.###.##...#.....####.#..#..#.##.#....##..#.####....##...##..#...#......#.#.......#.......##..####..#...#.#.#...##..#.#..###..#####........#..####......#..#

#..#.
#....
##..#
..#..
..###`

/*

--- Day 20: Trench Map ---

With the scanners fully deployed, you turn their attention to mapping the floor of the ocean trench.

When you get back the image from the scanners, it seems to just be random noise. Perhaps you can combine an image enhancement algorithm and the input image (your puzzle input) to clean it up a little.

For example:

..#.#..#####.#.#.#.###.##.....###.##.#..###.####..#####..#....#..#..##..##
#..######.###...####..#..#####..##..#.#####...##.#.#..#.##..#.#......#.###
.######.###.####...#.##.##..#..#..#####.....#.#....###..#.##......#.....#.
.#..#..##..#...##.######.####.####.#.#...#.......#..#.#.#...####.##.#.....
.#..#...##.#.##..#...##.#.##..###.#......#.#.......#.#.#.####.###.##...#..
...####.#..#..#.##.#....##..#.####....##...##..#...#......#.#.......#.....
..##..####..#...#.#.#...##..#.#..###..#####........#..####......#..#

#..#.
#....
##..#
..#..
..###

The first section is the image enhancement algorithm. It is normally given on a single line, but it has been wrapped to multiple lines in this example for legibility. The second section is the input image, a two-dimensional grid of light pixels (#) and dark pixels (.).

The image enhancement algorithm describes how to enhance an image by simultaneously converting all pixels in the input image into an output image. Each pixel of the output image is determined by looking at a 3x3 square of pixels centered on the corresponding input image pixel. So, to determine the value of the pixel at (5,10) in the output image, nine pixels from the input image need to be considered: (4,9), (4,10), (4,11), (5,9), (5,10), (5,11), (6,9), (6,10), and (6,11). These nine input pixels are combined into a single binary number that is used as an index in the image enhancement algorithm string.

For example, to determine the output pixel that corresponds to the very middle pixel of the input image, the nine pixels marked by [...] would need to be considered:

# . . # .
#[. . .].
#[# . .]#
.[. # .].
. . # # #

Starting from the top-left and reading across each row, these pixels are ..., then #.., then .#.; combining these forms ...#...#.. By turning dark pixels (.) into 0 and light pixels (#) into 1, the binary number 000100010 can be formed, which is 34 in decimal.

The image enhancement algorithm string is exactly 512 characters long, enough to match every possible 9-bit binary number. The first few characters of the string (numbered starting from zero) are as follows:

0         10        20        30  34    40        50        60        70
|         |         |         |   |     |         |         |         |
..#.#..#####.#.#.#.###.##.....###.##.#..###.####..#####..#....#..#..##..##

In the middle of this first group of characters, the character at index 34 can be found: #. So, the output pixel in the center of the output image should be #, a light pixel.

This process can then be repeated to calculate every pixel of the output image.

Through advances in imaging technology, the images being operated on here are infinite in size. Every pixel of the infinite output image needs to be calculated exactly based on the relevant pixels of the input image. The small input image you have is only a small region of the actual infinite input image; the rest of the input image consists of dark pixels (.). For the purposes of the example, to save on space, only a portion of the infinite-sized input and output images will be shown.

The starting input image, therefore, looks something like this, with more dark pixels (.) extending forever in every direction not shown here:

...............
...............
...............
...............
...............
.....#..#......
.....#.........
.....##..#.....
.......#.......
.......###.....
...............
...............
...............
...............
...............

By applying the image enhancement algorithm to every pixel simultaneously, the following output image can be obtained:

...............
...............
...............
...............
.....##.##.....
....#..#.#.....
....##.#..#....
....####..#....
.....#..##.....
......##..#....
.......#.#.....
...............
...............
...............
...............

Through further advances in imaging technology, the above output image can also be used as an input image! This allows it to be enhanced a second time:

...............
...............
...............
..........#....
....#..#.#.....
...#.#...###...
...#...##.#....
...#.....#.#...
....#.#####....
.....#.#####...
......##.##....
.......###.....
...............
...............
...............

Truly incredible - now the small details are really starting to come through. After enhancing the original input image twice, 35 pixels are lit.

Start with the original input image and apply the image enhancement algorithm twice, being careful to account for the infinite size of the images. How many pixels are lit in the resulting image?

--- Part Two ---

You still can't quite make out the details in the image. Maybe you just didn't enhance it enough.

If you enhance the starting input image in the above example a total of 50 times, 3351 pixels are lit in the final output image.

Start again with the original input image and apply the image enhancement algorithm 50 times. How many pixels are lit in the resulting image?

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
