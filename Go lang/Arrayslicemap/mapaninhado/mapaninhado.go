package main

import "fmt"

func main() {
	funcsPorLetra := map[string]map[string]float64{
		"G": {
			"Gabriel Silva": 1234.78,
			"Gustavo Neri":  2324.78,
		},
		"J": {
			"Joao jose":  1233.79,
			"Jose Lucas": 93827.87,
		},
		"P": {
			"Pedro junior": 984.56,
		},
	}

	delete(funcsPorLetra, "P")

	for letra, funcs := range funcsPorLetra {
		fmt.Println(letra, funcs)
	}
}
