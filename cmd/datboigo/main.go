package main

import (
	"fmt"
	"log"
	"os"
	"os/exec"
	"time"
)

// DatBoi is the single user in control of the game
type DatBoi struct {
	row int
	col int
}

// Siren is the type for the sirens chasing dat boi
type Siren struct {
	row int
	col int
}

var (
	maze    []string
	boi     DatBoi
	sirens  []*Siren
	score   int
	numBags int
	lives   = 1
	graphic Graphics
)

func init() {
	cbreakMode := exec.Command("/bin/stty", "cbreak", "-echo")
	cbreakMode.Stdin = os.Stdin

	fmt.Println("setup complete, in cbreak mode")

	err := cbreakMode.Run()
	if err != nil {
		log.Fatalf("unable to activate cbreak mode terminal: %v\n", err)
	}
}

func cleanup() {
	cookedMode := exec.Command("/bin/stty", "-cbreak", "echo")
	cookedMode.Stdin = os.Stdin

	err := cookedMode.Run()
	if err != nil {
		log.Fatalf("unable to activate cooked mode in terminal: %v\n", err)
	}
}

func main() {
	defer cleanup()

	err := loadMaze()
	if err != nil {
		log.Printf("error loading maze: %v\n", err)
		return
	}

	err = loadGraphics()
	if err != nil {
		log.Printf("error loading graphics: %v\n", err)
		return
	}

	input := make(chan string)
	go func(ch chan<- string) {
		for {
			input, err := readInput()
			if err != nil {
				log.Printf("error reading input: %v", err)
				ch <- "ESC"
			}
			ch <- input
		}
	}(input)

	for {

		select {
		case in := <-input:
			if in == "ESC" {
				lives = 0
			}
			movePlayer(in)
		default:
		}

		moveSirens()

		for _, s := range sirens {
			if boi.row == s.row && boi.col == s.col {
				lives = 0
			}
		}

		printScreen()

		if numBags == 0 || lives == 0 {
			if lives == 0 {
				moveCursor(boi.row, boi.col)
				fmt.Printf(graphic.Death)
				moveCursor(len(maze)+2, 0)
			}
			break
		}

		time.Sleep(200 * time.Millisecond)
	}
}
