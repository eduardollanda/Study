package main

import "fmt"

func notaParaConceito(n float64) string {
	var nota = int(n)

	switch nota {
	case 10:
		// usar o fallthrough para fazer com que execute tanto essa case como proxima case
		fallthrough
	case 9:
		return "A"
	case 8, 7:
		return "B"
	case 6, 5:
		return "C"
	case 4, 3:
		return "D"
	case 2, 1, 0:
		return "E"
	default:
		return "Nota Invalida"
	}
}

func main() {
	fmt.Println("Conceito:", notaParaConceito(8.8))
	fmt.Println("Conceito:", notaParaConceito(5))
	fmt.Println("Conceito:", notaParaConceito(6))
	fmt.Println("Conceito:", notaParaConceito(7))
}
