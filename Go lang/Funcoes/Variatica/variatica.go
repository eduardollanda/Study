package main

import "fmt"

//faz com que a funcao possa receber quantas variaves quiser
//de mesmo tipo

func media(numeros ...float64) float64 {
	total := 0.0
	for _, num := range numeros {
		total += num
	}
	//convertento o len de numeros para float64 para ser possivel a divisao
	return total / float64(len(numeros))
}

func main() {
	fmt.Printf("Média: %.2f ", media(2.3, 4.5, 8.3, 5.6))
}
