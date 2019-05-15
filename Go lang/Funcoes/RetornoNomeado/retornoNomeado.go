package main

import "fmt"

// eh possivel atribuir nome aos valores de retorno
func trocar(p1, p2 int) (primeiro, segundo int) {
	primeiro = p2
	segundo = p1
	return //retorno limpo
}

func main() {
	x, y := 2, 3
	trocar(x, y)
	fmt.Println(x, y)
}
