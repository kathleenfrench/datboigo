package main

import (
	"bufio"
	"encoding/json"
	"fmt"
	"math/rand"
	"os"
)

// Graphics holds the graphics configuration for the game
type Graphics struct {
	Boi   string `json:"boi"`
	Siren string `json:"siren"`
	Wall  string `json:"wall"`
	Bag   string `json:"bag"` // secure the bag!
	Death string `json:"death"`
	Space string `json:"space"`
	Use   bool   `json:"use_graphics"`
}

func loadGraphics() error {
	f, err := os.Open("./assets/graphics.json")
	if err != nil {
		return err
	}

	defer f.Close()

	decoder := json.NewDecoder(f)
	err = decoder.Decode(&graphic)
	if err != nil {
		return err
	}

	return nil
}

func printScreen() {
	clearScreen()
	for _, line := range maze {
		for _, char := range line {
			switch char {
			case '#':
				fmt.Printf(graphic.Wall + " ")
			case '.':
				fmt.Printf(graphic.Bag)
			default:
				fmt.Printf(graphic.Space)
			}
		}
		fmt.Printf("\n")
	}

	moveCursor(boi.row, boi.col)
	fmt.Printf(graphic.Boi)

	for _, s := range sirens {
		moveCursor(s.row, s.col)
		fmt.Printf(graphic.Siren)
	}

	moveCursor(len(maze)+1, 0)
	fmt.Printf("Score: %v\nLives: %v\n", score, lives)
}

func clearScreen() {
	fmt.Printf("\x1b[2J")
	moveCursor(0, 0)
}

func loadMaze() error {
	f, err := os.Open("./assets/maze.txt")
	if err != nil {
		return err
	}

	defer f.Close()

	scanner := bufio.NewScanner(f)

	for scanner.Scan() {
		line := scanner.Text()
		maze = append(maze, line)
	}

	for row, line := range maze {
		for col, char := range line {
			switch char {
			case 'B':
				boi = DatBoi{row, col}
			case 'S':
				sirens = append(sirens, &Siren{row, col})
			case '.':
				numBags++
			}
		}
	}

	return nil
}

func drawDirection() string {
	dir := rand.Intn(4)
	move := map[int]string{
		0: "UP",
		1: "DOWN",
		2: "RIGHT",
		3: "LEFT",
	}
	return move[dir]
}
