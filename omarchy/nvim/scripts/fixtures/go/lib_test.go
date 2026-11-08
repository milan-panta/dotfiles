package main

import "testing"

func TestAddOk(t *testing.T) {
	if Add(1, 2) != 3 {
		t.Fatal("bad")
	}
}

func TestAddBad(t *testing.T) {
	got := Add(1, 2)
	if got != 4 {
		t.Fatalf("got %d", got)
	}
}
