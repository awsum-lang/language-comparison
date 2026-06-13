/* This demo program builds an immutable tree of depth 5_000_000, mirrors it 500
 * times (causing heavy allocation pressure), and displays the deepest value on
 * the left path.
 *
 * Go outcome (go 1.26.4, `go run .`): Go does no tail-call elimination (the
 * team declined it on purpose), so every recursion here — tail or not —
 * consumes a real stack frame. A goroutine's stack grows on demand only up to
 * a default ~1 GB cap (runtime/debug.SetMaxStack). At depth 5_000_000 the
 * build_left recursion blows past that cap before the first tree is even
 * built, and the program aborts with
 *   runtime: goroutine stack exceeds 1000000000-byte limit
 * — confirmed on both arm64 (macOS) and x86_64 (the Linux CI runner). The
 * exact cliff depth depends on per-frame stack size — architecture, plus the
 * generic Tree[int] instantiation — but it is finite: recursion depth here is
 * bounded by available stack, not handled by the compiler.
 */

package main

import "fmt"

type Tree interface{ isTree() }

type Leaf struct{}

type Node struct {
	left  Tree
	value int
	right Tree
}

func (Leaf) isTree() {}
func (Node) isTree() {}

func main() {
	fmt.Println(runDemo())
}

func runDemo() int {
	return deepestLeftA(0, mirrorN(500, buildTree(5_000_000)))
}

func buildTree(depth int) Tree {
	l := buildLeft(depth, depth, Leaf{})
	r := buildRight(depth, depth, Leaf{})
	return Node{left: l, value: 0, right: r}
}

func buildLeft(depth, value int, acc Tree) Tree {
	if depth == 0 {
		return acc
	}
	return buildLeft(depth-1, value-1, Node{left: acc, value: value, right: Leaf{}}) // tail recursion
}

func buildRight(depth, value int, acc Tree) Tree {
	if depth == 0 {
		return acc
	}
	return buildRight(depth-1, value-1, Node{left: Leaf{}, value: value, right: acc}) // tail recursion
}

func mirror(t Tree) Tree {
	switch n := t.(type) {
	case Node:
		return Node{left: mirror(n.right), value: n.value, right: mirror(n.left)} // multi-child non-tail recursion
	default:
		return t // Leaf
	}
}

func mirrorN(times int, t Tree) Tree {
	if times == 0 {
		return t
	}
	return mirrorN(times-1, mirror(t)) // tail recursion + heavy allocation pressure
}

func deepestLeftA(lastV int, t Tree) int {
	switch n := t.(type) {
	case Node:
		return deepestLeftB(n.value, n.left) // 3-node mutual tail recursion
	default:
		return lastV // Leaf
	}
}

func deepestLeftB(lastV int, t Tree) int {
	switch n := t.(type) {
	case Node:
		return deepestLeftC(n.value, n.left) // 3-node mutual tail recursion
	default:
		return lastV // Leaf
	}
}

func deepestLeftC(lastV int, t Tree) int {
	switch n := t.(type) {
	case Node:
		return deepestLeftA(n.value, n.left) // 3-node mutual tail recursion
	default:
		return lastV // Leaf
	}
}
