(* This demo program builds an immutable tree of depth 100_000, mirrors it 500
   times (causing heavy allocation pressure), and displays the deepest value on
   the left path.

   F# outcome: `Stack overflow.` process abort inside `mirror` on the very
   first call. `Node (mirror r, v, mirror l)` is multi-child non-tail
   self-recursion. The CLR honours F#'s `tail.` CIL prefix for tail calls
   (so `deepestLeftA/B/C` would run as a real mutual-tail loop, unlike on
   the JVM), but `mirror`'s two calls aren't in tail position — the result
   is wrapped in `Node`, so each recursion grows the OS thread stack. ~75k
   frames in, .NET exhausts the main thread's stack (~8 MB on macOS) and
   the runtime aborts the process. Output never reaches stdout.
*)
module Main

type Tree<'a> = Leaf | Node of Tree<'a> * 'a * Tree<'a>

let rec buildLeft (depth: int) (value: int) (acc: Tree<int>) : Tree<int> =
    if depth = 0 then acc
    else buildLeft (depth - 1) (value - 1) (Node (acc, value, Leaf)) // tail recursion

let rec buildRight (depth: int) (value: int) (acc: Tree<int>) : Tree<int> =
    if depth = 0 then acc
    else buildRight (depth - 1) (value - 1) (Node (Leaf, value, acc)) // tail recursion

let buildTree (depth: int) : Tree<int> =
    let l = buildLeft depth depth Leaf
    let r = buildRight depth depth Leaf
    Node (l, 0, r)

let rec mirror (tree: Tree<'a>) : Tree<'a> =
    match tree with
    | Leaf -> Leaf
    | Node (l, v, r) -> Node (mirror r, v, mirror l) // multi-child non-tail recursion

let rec mirrorN (times: int) (tree: Tree<'a>) : Tree<'a> =
    if times = 0 then tree
    else mirrorN (times - 1) (mirror tree) // tail recursion + heavy allocation pressure

let rec deepestLeftA (lastV: 'a) (tree: Tree<'a>) : 'a =
    match tree with
    | Leaf -> lastV
    | Node (l, v, _) -> deepestLeftB v l // 3-node mutual tail recursion

and deepestLeftB (lastV: 'a) (tree: Tree<'a>) : 'a =
    match tree with
    | Leaf -> lastV
    | Node (l, v, _) -> deepestLeftC v l // 3-node mutual tail recursion

and deepestLeftC (lastV: 'a) (tree: Tree<'a>) : 'a =
    match tree with
    | Leaf -> lastV
    | Node (l, v, _) -> deepestLeftA v l // 3-node mutual tail recursion

let runDemo : int = deepestLeftA 0 (mirrorN 500 (buildTree 100_000))

[<EntryPoint>]
let main _ =
    printfn "%d" runDemo
    0
