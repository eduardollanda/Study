package main

import "fmt"

func main() {

	// Provando que os dois slices apontam para o mesmo array
	s1 := make([]int, 10, 20)
	s2 := append(s1, 1, 2, 3)

	fmt.Println(s1, s2)

	s1[0] = 7
	fmt.Println(s1, s2)

}
