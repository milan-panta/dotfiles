package main

import "fmt"

func main() {
	values := Squares(5)
	total := 0
	for _, v := range values {
		total = Add(total, v)
	}
	fmt.Println("total", total)
}
