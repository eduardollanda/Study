package main

import "fmt"

// armazenando o valor de uma funcao como variavel
var soma = func(a, b int) int {
	return a + b
}

func main() {

	fmt.Println(soma(2, 3))

	sub := func(a, b int) int {
		return a - b
	}

	fmt.Println(sub(5, 2))
}
