package main

import "fmt"

func main() {
	// var aprovados map[int]string
	// mapas devem ser inicializados

	aprovados := make(map[int]string)

	aprovados[1234556789] = "maria"
	aprovados[1783136187] = "eduardo"
	aprovados[1123543534] = "igor"

	fmt.Println(aprovados)

	for cpf, nome := range aprovados {
		fmt.Printf("%s (CPF: %d )\n", nome, cpf)
	}

	// para buscar por um valor basta procurar por sua chave
	fmt.Println(aprovados[1234556789])

	// o mesmo serve para a funcao delete
	delete(aprovados, 1234556789)
	fmt.Println(aprovados[1234556789])
}
