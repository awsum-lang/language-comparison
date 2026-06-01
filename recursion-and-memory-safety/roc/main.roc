# This demo program builds an immutable tree of depth 100_000, mirrors it 500
# times (causing heavy allocation pressure), and displays the deepest value on
# the left path.
#
# Roc outcome (alpha4-rolling, nightly 2026-04-10): does not compile. Roc's
# type alias form (`:`) explicitly rejects recursion, and the nominal form
# (`:=`) used here is syntactically valid for self-referential types but the
# compiler stack-overflows when compiling any recursive function over such
# a type — even at tree depth 1. None of the alpha4 builtins (Bool, Result,
# Color) are recursive types; no working example of a recursive nominal type
# could be found in the Roc source tree. This file is left in maximally-
# close-to-Haskell form; the demo will run once Roc's compiler stops
# overflowing on recursive functions over recursive nominal types.

Tree(a) := [Leaf, Node(Tree(a), a, Tree(a))]

build_left : I64, I64, Tree(I64) -> Tree(I64)
build_left = |depth, value, acc|
    if depth == 0
        acc
    else
        build_left(depth - 1, value - 1, Tree.Node(acc, value, Tree.Leaf)) # tail recursion

build_right : I64, I64, Tree(I64) -> Tree(I64)
build_right = |depth, value, acc|
    if depth == 0
        acc
    else
        build_right(depth - 1, value - 1, Tree.Node(Tree.Leaf, value, acc)) # tail recursion

build_tree : I64 -> Tree(I64)
build_tree = |depth| {
    l = build_left(depth, depth, Tree.Leaf)
    r = build_right(depth, depth, Tree.Leaf)
    Tree.Node(l, 0, r)
}

mirror : Tree(a) -> Tree(a)
mirror = |tree| match tree {
    Tree.Leaf => Tree.Leaf
    Tree.Node(l, v, r) => Tree.Node(mirror(r), v, mirror(l)) # multi-child non-tail recursion
}

mirror_n : I64, Tree(a) -> Tree(a)
mirror_n = |times, tree|
    if times == 0
        tree
    else
        mirror_n(times - 1, mirror(tree)) # tail recursion + heavy allocation pressure

deepest_left_a : I64, Tree(I64) -> I64
deepest_left_a = |last_v, tree| match tree {
    Tree.Leaf => last_v
    Tree.Node(l, v, _) => deepest_left_b(v, l) # 3-node mutual tail recursion
}

deepest_left_b : I64, Tree(I64) -> I64
deepest_left_b = |last_v, tree| match tree {
    Tree.Leaf => last_v
    Tree.Node(l, v, _) => deepest_left_c(v, l) # 3-node mutual tail recursion
}

deepest_left_c : I64, Tree(I64) -> I64
deepest_left_c = |last_v, tree| match tree {
    Tree.Leaf => last_v
    Tree.Node(l, v, _) => deepest_left_a(v, l) # 3-node mutual tail recursion
}

main! = |_args| {
    result = deepest_left_a(0, mirror_n(500, build_tree(100_000)))
    echo!(result.to_str())
    Ok({})
}
