(* This program builds an immutable tree of depth `treeDepth`, mirrors it
   `mirrorCount` times, and prints the deepest value on the left path. Both are
   read from argv; the recorded run (assert-behavior.sh) passes `45000000 1`.

   OCaml outcome (ocaml 5.4.1, native via ocamlopt, `./main 45000000 1`):
   `Fatal error: exception Stack_overflow`, no output. OCaml does TCO for self
   and mutual tail calls (build_left / build_right / mirror_n /
   deepest_left_{a,b,c} run in constant stack), and OCaml 5 runs the non-tail
   `mirror` on a growable stack far past the 8 MB C `ulimit -s` — so it clears
   5_000_000, where every fixed-stack language (Java, Rust, …) died in the
   tens-to-hundreds of thousands. But growable is not unbounded: like Go's
   goroutine stack, it postpones the limit rather than removing it. `mirror`
   recurses to the tree depth, and deep enough it exhausts even the growable
   stack and raises Stack_overflow. So OCaml is not stack-safe — its ceiling is
   just higher, and platform-dependent: this macOS box aborts by 35M, the Linux
   CI runner clears that, so the recorded run uses 45_000_000 to cross the
   higher one. awsum and Haskell, bounded by memory rather than stack, keep
   going at this depth. (Pre-5.0 OCaml ran on the fixed C stack and overflowed
   far shallower.) *)

type 'a tree = Leaf | Node of 'a tree * 'a * 'a tree

let rec build_left depth value acc =
  if depth = 0 then acc
  else build_left (depth - 1) (value - 1) (Node (acc, value, Leaf)) (* tail recursion *)

let rec build_right depth value acc =
  if depth = 0 then acc
  else build_right (depth - 1) (value - 1) (Node (Leaf, value, acc)) (* tail recursion *)

let build_tree depth =
  let l = build_left depth depth Leaf in
  let r = build_right depth depth Leaf in
  Node (l, 0, r)

let rec mirror t =
  match t with
  | Leaf -> Leaf
  | Node (l, v, r) -> Node (mirror r, v, mirror l) (* multi-child non-tail recursion *)

let rec mirror_n times t =
  if times = 0 then t
  else mirror_n (times - 1) (mirror t) (* tail recursion *)

let rec deepest_left_a last_v t =
  match t with
  | Leaf -> last_v
  | Node (l, v, _) -> deepest_left_b v l (* 3-node mutual tail recursion *)

and deepest_left_b last_v t =
  match t with
  | Leaf -> last_v
  | Node (l, v, _) -> deepest_left_c v l (* 3-node mutual tail recursion *)

and deepest_left_c last_v t =
  match t with
  | Leaf -> last_v
  | Node (l, v, _) -> deepest_left_a v l (* 3-node mutual tail recursion *)

let run_demo tree_depth mirror_count =
  deepest_left_a 0 (mirror_n mirror_count (build_tree tree_depth))

let () =
  let tree_depth = int_of_string Sys.argv.(1) in
  let mirror_count = int_of_string Sys.argv.(2) in
  Printf.printf "%d\n" (run_demo tree_depth mirror_count)
