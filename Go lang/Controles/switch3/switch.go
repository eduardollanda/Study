package main

import (
	"fmt"
	"time"
)

func tipo(i interface{}) string {
	switch i.(type) {
	case int:
		return "Inteiro"
	case float32, float64:
		return "Real"
	case string:
		return "String"
	case func():
		return "Função"
	default:
		return "Não sei"
	}
}
func main() {

	fmt.Println(tipo("string"))
	fmt.Println(tipo(func() {}))
	fmt.Println(tipo(6514))
	fmt.Println(tipo(45.5))
	fmt.Println(tipo(time.Now()))

}
