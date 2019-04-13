package main

import (
	"fmt"
	"os"
)

func moveCursor(row, col int) {
	if graphic.Use {
		fmt.Printf("\x1b[%d;%df", row+1, col*2+1)
	} else {
		fmt.Printf("\x1b[%d;%df", row+1, col+1)
	}
}

func movePlayer(dir string) {
	boi.row, boi.col = makeMove(boi.row, boi.col, dir)

	switch maze[boi.row][boi.col] {
	case '.':
		numBags--
		score++
		maze[boi.row] = maze[boi.row][0:boi.col] + " " + maze[boi.row][boi.col+1:]
	}
}

func moveSirens() {
	for _, s := range sirens {
		dir := drawDirection()
		s.row, s.col = makeMove(s.row, s.col, dir)
	}
}

func makeMove(oldRow, oldCol int, dir string) (newRow, newCol int) {
	newRow, newCol = oldRow, oldCol

	switch dir {
	case "UP":
		newRow = newRow - 1
		if newRow < 0 {
			newRow = len(maze) - 1
		}
	case "DOWN":
		newRow = newRow + 1
		if newRow == len(maze)-1 {
			newRow = 0
		}
	case "RIGHT":
		newCol = newCol + 1
		if newCol == len(maze[0]) {
			newCol = 0
		}
	case "LEFT":
		newCol = newCol - 1
		if newCol < 0 {
			newCol = len(maze[0]) - 1
		}
	}

	if maze[newRow][newCol] == '#' {
		newRow = oldRow
		newCol = oldCol
	}

	return
}

func readInput() (string, error) {
	buffer := make([]byte, 100)

	count, err := os.Stdin.Read(buffer)
	if err != nil {
		return "", err
	}

	if count == 1 && buffer[0] == 0x1b {
		return "ESC", nil
	} else if count >= 3 {
		if buffer[0] == 0x1b && buffer[1] == '[' {
			switch buffer[2] {
			case 'A':
				return "UP", nil
			case 'B':
				return "DOWN", nil
			case 'C':
				return "RIGHT", nil
			case 'D':
				return "LEFT", nil
			}
		}
	}

	return "", nil
}
