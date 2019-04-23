package main

import "fmt"

func notaParaConceito(n float64) string {
	if n >= 9 && n <= 10 {
		return "A"
	} else if n >= 8 && n <= 9 {
		return "B"
	} else if n >= 5 && n <= 8 {
		return "C"
	} else if n >= 3 && n <= 5 {
		return "D"
	} else {
		return "E"
	}

}
func main() {
	fmt.Println(notaParaConceito(7))
	fmt.Println(notaParaConceito(3.4))
	fmt.Println(notaParaConceito(9))
}
