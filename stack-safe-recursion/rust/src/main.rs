/* This program builds an immutable tree of depth `treeDepth`, mirrors it
 * `mirrorCount` times, and prints the deepest value on the left path. Both are
 * read from argv; the recorded run (assert-behavior.sh) passes `5000000 1`.
 *
 * Rust outcome (rustc 1.93.1, `cargo run --release -- 5000000 1`): `fatal runtime
 * error: stack overflow, aborting` inside `build_left`, before the first
 * tree even exists. There is no tail-call elimination anywhere — the
 * release asm on both aarch64 and x86_64 keeps every recursive fn a
 * genuine self-call; even `build_left`'s call is in tail position only
 * syntactically, because Drop of the owned values forces a live frame
 * around it. Stack use is therefore linear in depth: ~96-byte frames ×
 * depth 5_000_000 ≈ 29 MB on aarch64 (~24 MB on x86_64) — more than three
 * times any default 8 MB main-thread stack, so the abort does not depend on
 * the platform's stack budget. mirror, mirror_n and deepest_left_a/b/c
 * never get a chance to run.
 */

use std::env;

enum Tree<A> {
    Leaf,
    Node(Box<Tree<A>>, A, Box<Tree<A>>),
}

fn main() {
    let args: Vec<String> = env::args().collect();
    let tree_depth: i32 = args[1].parse().unwrap();
    let mirror_count: i32 = args[2].parse().unwrap();
    println!("{}", run_demo(tree_depth, mirror_count));
}

fn run_demo(tree_depth: i32, mirror_count: i32) -> i32 {
    deepest_left_a(0, mirror_n(mirror_count, build_tree(tree_depth)))
}

fn build_tree(depth: i32) -> Tree<i32> {
    let l = build_left(depth, depth, Tree::Leaf);
    let r = build_right(depth, depth, Tree::Leaf);
    Tree::Node(Box::new(l), 0, Box::new(r))
}

fn build_left(depth: i32, value: i32, acc: Tree<i32>) -> Tree<i32> {
    if depth == 0 {
        acc
    } else {
        build_left(
            depth - 1,
            value - 1,
            Tree::Node(Box::new(acc), value, Box::new(Tree::Leaf)),
        ) // tail recursion
    }
}

fn build_right(depth: i32, value: i32, acc: Tree<i32>) -> Tree<i32> {
    if depth == 0 {
        acc
    } else {
        build_right(
            depth - 1,
            value - 1,
            Tree::Node(Box::new(Tree::Leaf), value, Box::new(acc)),
        ) // tail recursion
    }
}

fn mirror<A>(t: Tree<A>) -> Tree<A> {
    match t {
        Tree::Leaf => Tree::Leaf,
        Tree::Node(l, v, r) => Tree::Node(Box::new(mirror(*r)), v, Box::new(mirror(*l))), // multi-child non-tail recursion
    }
}

fn mirror_n<A>(times: i32, t: Tree<A>) -> Tree<A> {
    if times == 0 {
        t
    } else {
        mirror_n(times - 1, mirror(t)) // tail recursion
    }
}

fn deepest_left_a<A>(last_v: A, t: Tree<A>) -> A {
    match t {
        Tree::Leaf => last_v,
        Tree::Node(l, v, _) => deepest_left_b(v, *l), // 3-node mutual tail recursion
    }
}

fn deepest_left_b<A>(last_v: A, t: Tree<A>) -> A {
    match t {
        Tree::Leaf => last_v,
        Tree::Node(l, v, _) => deepest_left_c(v, *l), // 3-node mutual tail recursion
    }
}

fn deepest_left_c<A>(last_v: A, t: Tree<A>) -> A {
    match t {
        Tree::Leaf => last_v,
        Tree::Node(l, v, _) => deepest_left_a(v, *l), // 3-node mutual tail recursion
    }
}
