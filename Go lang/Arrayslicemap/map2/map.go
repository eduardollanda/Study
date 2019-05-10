package main

import "fmt"

func main() {
	funcESalarios := map[string]float64{
		"eduardo": 12313.50,
		"igor":    727.50,
		"antonio": 37824.00,
	}
	funcESalarios["rafael"] = 1233.0

	// nao tem problema tentar apagar um elemento n existente
	delete(funcESalarios, "inexistente")

	for nome, salario := range funcESalarios {
		fmt.Printf("%s recebe R$: %.2f\n", nome, salario)
	}
}
