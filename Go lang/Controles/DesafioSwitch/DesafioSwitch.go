package main

import "fmt"

func main() {

	fmt.Println(notaParaConceito(6))
	fmt.Println(notaParaConceito(3))
	fmt.Println(notaParaConceito(8))

}
func notaParaConceito(n float64) string {

	switch true {
	case n < 2:
		return "E"
	case n < 5:
		return "D"
	case n < 8:
		return "C"
	case n < 9:
		return "B"
	case n < 10:
		return "A"
	default:
		return "Nota invalida"
	}

}
