package main

import "runtime/debug"

func f3() {
	// mostra toda a ilha de execucao
	debug.PrintStack()
}

func f2() {
	f3()
}

func f1() {
	f2()
}

func main() {
	f1()
}
