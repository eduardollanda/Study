package main

import (
	"fmt"
	"time"
)

func main() {
	horadodia()
}
func horadodia() {
	t := time.Now()

	// caso de switch true
	//primeiro caso que for verdadeiro ele vai entrar
	switch true {
	case t.Hour() < 12:
		fmt.Println("Bom dia")
	case t.Hour() < 18:
		fmt.Println("Boa tarde")
	default:
		fmt.Println("Boa noite")
	}
}
