/* This demo program builds an immutable tree of depth 100_000, mirrors it 500
 * times (causing heavy allocation pressure), and displays the deepest value on
 * the left path.
 *
 * Rust outcome: `fatal runtime error: stack overflow, aborting` inside
 * `build_left` — the very first call from `build_tree`. Rust has no
 * guaranteed TCO; even though `build_left`'s recursive call is in tail
 * position, the Drop semantics of owned values (`acc`, the freshly built
 * `Box`es) force the compiler to keep a stack frame around to run
 * destructors after return, so LLVM cannot rewrite the call into a jump
 * even at `-C opt-level=3 -C lto=fat`. The depth-100_000 chain exhausts
 * the main thread's stack (~8 MB on macOS) before `build_tree` finishes,
 * which means `mirror`, `mirror_n` and `deepest_left_a/b/c` never even
 * get a chance to run.
 */

enum Tree<A> {
    Leaf,
    Node(Box<Tree<A>>, A, Box<Tree<A>>),
}

fn main() {
    println!("{}", run_demo());
}

fn run_demo() -> i32 {
    deepest_left_a(0, mirror_n(500, build_tree(100_000)))
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
        mirror_n(times - 1, mirror(t)) // tail recursion + heavy allocation pressure
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
