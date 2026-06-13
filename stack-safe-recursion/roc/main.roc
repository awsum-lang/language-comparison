# This program builds an immutable tree of depth `treeDepth`, mirrors it
# `mirrorCount` times, and prints the deepest value on the left path. Both are
# read from argv; the recorded run (assert-behavior.sh) passes `5000000 1`.
#
# Roc outcome (nightly 2026-06-12, `release-fast-f964cdab`, `roc main.roc -- 5000000 1`):
# runtime crash — "Roc crashed: This Roc program overflowed its stack memory." —
# already on build_left's plain tail recursion. `roc main.roc` runs the program in Roc's
# interpreter, which does no TCO of any kind, so mirror and
# deepest_left_{a,b,c} never get a chance to run. The crash message carries
# no location — it is the whole diagnostic.

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
        mirror_n(times - 1, mirror(tree)) # tail recursion

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

parse_arg = |args, i| match List.get(args, i) {
    Ok(s) => match I64.from_str(s) {
        Ok(n) => n
        Err(_) => 0
    }
    Err(_) => 0
}

main! = |args| {
    tree_depth = parse_arg(args, 0)
    mirror_count = parse_arg(args, 1)
    result = deepest_left_a(0, mirror_n(mirror_count, build_tree(tree_depth)))
    echo!(result.to_str())
    Ok({})
}
