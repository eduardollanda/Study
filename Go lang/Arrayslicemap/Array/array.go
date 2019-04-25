package main

import "fmt"

func main() {
	//array tem estrutura homogênea e estática

	var notas [3]float64

	notas[0], notas[1], notas[2] = 7.4, 8.2, 9.1

	fmt.Println(notas)

	var total = 0.0
	for i := 0; i < len(notas); i++ {
		total += notas[i]
	}

	media := total / float64(len(notas))

	fmt.Printf("Media :%.2f", media)
}
