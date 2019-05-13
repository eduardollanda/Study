package main

import "fmt"

// funcao puro, nao afeta nada fora da funcao
func f1() {
	fmt.Println("F1")
}

// nome da variavel seguido de seu tipo
func f2(p1 string, p2 string) {
	fmt.Printf("F2: %s %s \n", p1, p2)
}

// se a funcao retornar algo, deve ser declarado seu tipo de retorno
func f3() string {
	return "F3"
}

// se tiver parametros do mesmo tipo podem ser declarados juntos
func f4(p1, p2 string) string {
	return fmt.Sprintf("F4 : %s %s", p1, p2)
}

// eh possivel ter mais de um retorno em uma funcao
func f5() (string, string) {
	return "Retorno 1", "Retorno 2"
}

func main() {
	f1()
	f2("string 1", " string2")
	fmt.Println(f3())
	fmt.Println(f4("string 1", " string2"))
	
	r51, r52 := f5()
	fmt.Println("F5", r51, r52)
}
