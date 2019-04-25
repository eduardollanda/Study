package main

import "fmt"

func main() {

	numeros := [...]int{1, 2, 3, 4, 5, 6, 7}

	for i, num := range numeros {
		fmt.Printf("indice %d) elemento %d\n", i, num)
	}

	// colocar "_" para ignorar um dos elementos
	for _, num := range numeros {
		fmt.Println(num)
	}
}
