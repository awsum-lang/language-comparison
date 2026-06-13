/* This demo program builds an immutable tree of depth 300_000, mirrors it 500
   times (causing heavy allocation pressure), and displays the deepest value on
   the left path.

   Koka outcome (3.2.3, -O2): SIGSEGV (exit code -11) inside `mirror` on the
   first invocation. Koka's TCO handles self-recursive tail calls
   (`build-left`/`build-right`/`mirror-n`) and *mutual* tail calls
   (`deepest-left-{a,b,c}`) — both unlike JVM/JS targets. But `mirror` is
   multi-child non-tail recursion (`Node(mirror(r), v, mirror(l))`) and there
   is no compiler transform for that shape: each level is a real frame on the
   underlying C call stack, which runs out long before depth 300_000 and
   kills the process with SIGSEGV.

   Koka also requires every recursive function whose termination it cannot
   structurally prove (recursion on `int`, mutual recursion) to declare the
   `div` (divergence) effect in its return type — that's why this file
   reads `: div tree<int>` and `: div a` where Haskell just writes the
   result type.
*/
module main

type tree<a>
  Leaf
  Node(left : tree<a>, value : a, right : tree<a>)

fun build-left(depth : int, value : int, acc : tree<int>) : div tree<int>
  if depth == 0 then acc
  else build-left(depth - 1, value - 1, Node(acc, value, Leaf)) // tail recursion

fun build-right(depth : int, value : int, acc : tree<int>) : div tree<int>
  if depth == 0 then acc
  else build-right(depth - 1, value - 1, Node(Leaf, value, acc)) // tail recursion

fun build-tree(depth : int) : div tree<int>
  val l = build-left(depth, depth, Leaf)
  val r = build-right(depth, depth, Leaf)
  Node(l, 0, r)

fun mirror(t : tree<a>) : tree<a>
  match t
    Leaf -> Leaf
    Node(l, v, r) -> Node(mirror(r), v, mirror(l)) // multi-child non-tail recursion

fun mirror-n(times : int, t : tree<a>) : div tree<a>
  if times == 0 then t
  else mirror-n(times - 1, mirror(t)) // tail recursion + heavy allocation pressure

fun deepest-left-a(last-v : a, t : tree<a>) : div a
  match t
    Leaf -> last-v
    Node(l, v, _) -> deepest-left-b(v, l) // 3-node mutual tail recursion

fun deepest-left-b(last-v : a, t : tree<a>) : div a
  match t
    Leaf -> last-v
    Node(l, v, _) -> deepest-left-c(v, l) // 3-node mutual tail recursion

fun deepest-left-c(last-v : a, t : tree<a>) : div a
  match t
    Leaf -> last-v
    Node(l, v, _) -> deepest-left-a(v, l) // 3-node mutual tail recursion

pub fun main()
  println(deepest-left-a(0, mirror-n(500, build-tree(300000))))
