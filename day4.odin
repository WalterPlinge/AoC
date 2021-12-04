package day_4

import "core:fmt"
import "core:os"
import "core:slice"
import "core:strconv"
import "core:strings"



Board :: [5][5]int



main :: proc (
) {
	fmt.println( "Day 4" )

	list   : [       ]int  ; defer delete( list   )
	boards : [dynamic]Board; defer delete( boards )

	{ // Load input data
		when #config( example, false ) {
			data := example_data
		} else {
			data, _ := os.read_entire_file( "day4.txt" ); defer delete(  data  )
		}

		fields  := strings.fields( string( data ) )
		numbers := strings.split( fields[ 0 ], "," ); defer delete( numbers )
		list     = slice.mapper( numbers, proc (
			s : string,
		) -> int {
			return strconv.atoi( s )
		} )
		for i := 1; i < len( fields ); i += 5 * 5 {
			append( &boards, Board{} )
			board := &boards[ len( boards ) - 1 ]
			for y in 0 ..< 5 {
				for x in 0 ..< 5 {
					board[ y ][ x ] = strconv.atoi( fields[ i + y * 5 + x ] )
				}
			}
		}
	}



	fmt.println( "\t1) What will your final score be if you choose that board?" )

	{ // Part 1
		boards_p1 := slice.clone( boards[:] ); defer delete( boards_p1 )
		score : int
		game_p1: for n in list {
			for b in &boards_p1 {
				mark_value( &b, n )
				if check_board( b ) {
					score = calculate_score( b, n )
					break game_p1
				}
			}
		}
		fmt.println( "\t\ta)", score )
	}



	fmt.println( "\t2) Once it wins, what would its final score be?" )

	{ // Part 2
		boards_p2 := slice.clone( boards[:] ); defer delete( boards_p2 )
		score  : int
		solved : int
		game_p2: for n in list {
			for b in &boards_p2 {
				if check_board( b ) { // bug: we should skip already solved boards
					continue
				}
				mark_value( &b, n )
				if check_board( b ) {
					score   = calculate_score( b, n )
					solved += 1
					if solved == len( boards_p2 ) {
						break game_p2
					}
				}
			}
		}
		fmt.println( "\t\ta)", score )
	}

	{ // Part 2 (version 2)
		/*
			we can swap solved boards with the back of the list
			this means we only iterate known unsolved boards
			this avoids the bug from version 1 where previously solved boards affect the state by being checked again
			loop up to      v
			[ , , , , , , , , ]
			loop up to    v
			[ , , , , , , , x ]
		*/
		boards_p2v2  := slice.clone( boards[:] ); defer delete( boards_p2v2 )
		score, count := 0, len( boards_p2v2 ) - 1
		game_p2v2: for n in list {
			for i := 0; i <= count; i += 1 { // bug: count is a valid board, need <=
				b := &boards_p2v2[ i ]
				mark_value( b, n )
				if check_board( b^ ) {
					score = calculate_score( b^, n )
					boards_p2v2[ i ], boards_p2v2[ count ] \
						= boards_p2v2[ count ], boards_p2v2[ i ]
					count -= 1
					i     -= 1 // bug: swapping the last board means we need to check i again
				}
			}
		}
		fmt.println( "\t\ta)", score )
	}
}



calculate_score :: proc (
	board : Board,
	value : int,
) -> int {
	score : int
	for y in 0 ..< 5 {
		for x in 0 ..< 5 {
			if board[ y ][ x ] != -1 {
				score += board[ y ][ x ]
			}
		}
	}
	score *= value
	return score
}



check_board :: proc (
	board : Board,
) -> bool {
	for y in 0 ..< 5 {
		row_value : int
		for x in 0 ..< 5 {
			row_value += board[ y ][ x ]
		}
		if row_value == -1 * 5 {
			return true
		}
	}
	for x in 0 ..< 5 {
		column_value : int
		for y in 0 ..< 5 {
			column_value += board[ y ][ x ]
		}
		if column_value == -1 * 5 {
			return true
		}
	}
	return false
}



mark_value :: proc (
	board : ^Board,
	value : int,
) {
	for y in 0 ..< 5 {
		for x in 0 ..< 5 {
			if  board[ y ][ x ] == value {
				board[ y ][ x ] = -1
			}
		}
	}
}



example_data := \
`7,4,9,5,11,17,23,2,0,14,21,24,10,16,13,6,15,25,12,22,18,20,8,19,3,26,1

22 13 17 11  0
 8  2 23  4 24
21  9 14 16  7
 6 10  3 18  5
 1 12 20 15 19

 3 15  0  2 22
 9 18 13 17  5
19  8  7 25 23
20 11 10 24  4
14 21 16 12  6

14 21 17 24  4
10 16 15  9 19
18  8 23 26 20
22 11 13  6  5
 2  0 12  3  7`



/*

--- Day 4: Giant Squid ---

You're already almost 1.5km (almost a mile) below the surface of the ocean, already so deep that you can't see any sunlight. What you can see, however, is a giant squid that has attached itself to the outside of your submarine.

Maybe it wants to play bingo?

Bingo is played on a set of boards each consisting of a 5x5 grid of numbers. Numbers are chosen at random, and the chosen number is marked on all boards on which it appears. (Numbers may not appear on all boards.) If all numbers in any row or any column of a board are marked, that board wins. (Diagonals don't count.)

The submarine has a bingo subsystem to help passengers (currently, you and the giant squid) pass the time. It automatically generates a random order in which to draw numbers and a random set of boards (your puzzle input). For example:

7,4,9,5,11,17,23,2,0,14,21,24,10,16,13,6,15,25,12,22,18,20,8,19,3,26,1

22 13 17 11  0
 8  2 23  4 24
21  9 14 16  7
 6 10  3 18  5
 1 12 20 15 19

 3 15  0  2 22
 9 18 13 17  5
19  8  7 25 23
20 11 10 24  4
14 21 16 12  6

14 21 17 24  4
10 16 15  9 19
18  8 23 26 20
22 11 13  6  5
 2  0 12  3  7

After the first five numbers are drawn (7, 4, 9, 5, and 11), there are no winners, but the boards are marked as follows (shown here adjacent to each other to save space):

22 13 17 11  0         3 15  0  2 22        14 21 17 24  4
 8  2 23  4 24         9 18 13 17  5        10 16 15  9 19
21  9 14 16  7        19  8  7 25 23        18  8 23 26 20
 6 10  3 18  5        20 11 10 24  4        22 11 13  6  5
 1 12 20 15 19        14 21 16 12  6         2  0 12  3  7

After the next six numbers are drawn (17, 23, 2, 0, 14, and 21), there are still no winners:

22 13 17 11  0         3 15  0  2 22        14 21 17 24  4
 8  2 23  4 24         9 18 13 17  5        10 16 15  9 19
21  9 14 16  7        19  8  7 25 23        18  8 23 26 20
 6 10  3 18  5        20 11 10 24  4        22 11 13  6  5
 1 12 20 15 19        14 21 16 12  6         2  0 12  3  7

Finally, 24 is drawn:

22 13 17 11  0         3 15  0  2 22        14 21 17 24  4
 8  2 23  4 24         9 18 13 17  5        10 16 15  9 19
21  9 14 16  7        19  8  7 25 23        18  8 23 26 20
 6 10  3 18  5        20 11 10 24  4        22 11 13  6  5
 1 12 20 15 19        14 21 16 12  6         2  0 12  3  7

At this point, the third board wins because it has at least one complete row or column of marked numbers (in this case, the entire top row is marked: 14 21 17 24 4).

The score of the winning board can now be calculated. Start by finding the sum of all unmarked numbers on that board; in this case, the sum is 188. Then, multiply that sum by the number that was just called when the board won, 24, to get the final score, 188 * 24 = 4512.

To guarantee victory against the giant squid, figure out which board will win first. What will your final score be if you choose that board?

--- Part Two ---

On the other hand, it might be wise to try a different strategy: let the giant squid win.

You aren't sure how many bingo boards a giant squid could play at once, so rather than waste time counting its arms, the safe thing to do is to figure out which board will win last and choose that one. That way, no matter which boards it picks, it will win for sure.

In the above example, the second board is the last to win, which happens after 13 is eventually called and its middle column is completely marked. If you were to keep playing until this point, the second board would have a sum of unmarked numbers equal to 148 for a final score of 148 * 13 = 1924.

Figure out which board will win last. Once it wins, what would its final score be?

*/
