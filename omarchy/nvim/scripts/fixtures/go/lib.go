package main

func Add(a, b int) int {
	return a + b
}

func Squares(n int) []int {
	out := []int{}
	for i := 0; i < n; i++ {
		out = append(out, i*i)
	}
	return out
}
