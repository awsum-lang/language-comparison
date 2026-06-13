/* This demo program builds an immutable tree of depth 5_000_000, mirrors it 500
 * times (causing heavy allocation pressure), and displays the deepest value on
 * the left path.
 *
 * Scala 3 outcome: `java.lang.StackOverflowError` inside `mirror` on the very
 * first call. `Node(mirror(r), v, mirror(l))` is multi-child non-tail
 * self-recursion. The Scala compiler automatically rewrites self-recursive
 * *tail* calls into a `while` loop, but neither it nor the JVM has anything
 * for non-tail recursion — `@tailrec` is only a compile-time assertion that
 * a function IS tail-recursive, not what enables the optimization. The
 * depth-5_000_000 V-tree exhausts the JVM thread's default stack (~512 KB →
 * a few thousand frames) before any output is produced. `deepestLeftA/B/C`
 * would similarly overflow if reached, because Scala doesn't optimize mutual
 * tail recursion (annotating those with `@tailrec` would be a compile error,
 * confirming the limit).
 */

import scala.annotation.tailrec

enum Tree[+A]:
  case Leaf
  case Node(left: Tree[A], value: A, right: Tree[A])

@main def main(): Unit = println(runDemo)

def runDemo: Int = deepestLeftA(0, mirrorN(500, buildTree(5_000_000)))

def buildTree(depth: Int): Tree[Int] =
  val l = buildLeft(depth, depth, Tree.Leaf)
  val r = buildRight(depth, depth, Tree.Leaf)
  Tree.Node(l, 0, r)

@tailrec
def buildLeft(depth: Int, value: Int, acc: Tree[Int]): Tree[Int] =
  if depth == 0 then acc
  else buildLeft(depth - 1, value - 1, Tree.Node(acc, value, Tree.Leaf)) // tail recursion

@tailrec
def buildRight(depth: Int, value: Int, acc: Tree[Int]): Tree[Int] =
  if depth == 0 then acc
  else buildRight(depth - 1, value - 1, Tree.Node(Tree.Leaf, value, acc)) // tail recursion

def mirror[A](t: Tree[A]): Tree[A] = t match
  case Tree.Leaf => Tree.Leaf
  case Tree.Node(l, v, r) => Tree.Node(mirror(r), v, mirror(l)) // multi-child non-tail recursion

@tailrec
def mirrorN[A](times: Int, t: Tree[A]): Tree[A] =
  if times == 0 then t
  else mirrorN(times - 1, mirror(t)) // tail recursion + heavy allocation pressure

def deepestLeftA[A](lastV: A, t: Tree[A]): A = t match
  case Tree.Leaf => lastV
  case Tree.Node(l, v, _) => deepestLeftB(v, l) // 3-node mutual tail recursion

def deepestLeftB[A](lastV: A, t: Tree[A]): A = t match
  case Tree.Leaf => lastV
  case Tree.Node(l, v, _) => deepestLeftC(v, l) // 3-node mutual tail recursion

def deepestLeftC[A](lastV: A, t: Tree[A]): A = t match
  case Tree.Leaf => lastV
  case Tree.Node(l, v, _) => deepestLeftA(v, l) // 3-node mutual tail recursion
