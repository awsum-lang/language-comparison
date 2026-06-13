(* This program builds an immutable tree of depth `treeDepth`, mirrors it
   `mirrorCount` times, and prints the deepest value on the left path. Both are
   read from argv; the recorded run (assert-behavior.sh) passes `5000000 1`.

   F# outcome (`dotnet run -- 5000000 1`): `Stack overflow.` process abort inside `mirror` on the very
   first call — in every configuration (Debug or Release, tiered JIT or
   not). The F# compiler turns the self-tail calls of `buildLeft` /
   `buildRight` / `mirrorN` into IL loops, and the CLR honours the `tail.`
   prefix for the mutual `deepestLeftA/B/C` (unlike the JVM), so every tail
   shape here is safe at any depth. But `mirror`'s two calls aren't in tail
   position — the result is wrapped in `Node` — so each level is a real
   stack frame, and depth 5_000_000 needs far more stack than any thread
   gets, however small the optimizer makes the frames. Output never
   reaches stdout.
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
    else mirrorN (times - 1) (mirror tree) // tail recursion

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

let runDemo (treeDepth: int) (mirrorCount: int) : int =
    deepestLeftA 0 (mirrorN mirrorCount (buildTree treeDepth))

[<EntryPoint>]
let main argv =
    let treeDepth = int argv.[0]
    let mirrorCount = int argv.[1]
    printfn "%d" (runDemo treeDepth mirrorCount)
    0
