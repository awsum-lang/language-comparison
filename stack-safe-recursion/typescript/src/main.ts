/* This program builds an immutable tree of depth `treeDepth`, mirrors it
 * `mirrorCount` times, and prints the deepest value on the left path. Both are
 * read from argv; the recorded run (assert-behavior.sh) passes `5000000 1`.
 *
 * TypeScript outcome (`npm start -- 5000000 1`): `RangeError: Maximum call stack size exceeded` inside
 * `buildLeft` on the very first call. TypeScript compiles to plain JavaScript
 * and inherits the host engine's TCO story — and V8 (and every shipping JS
 * engine) does no TCO at all, even for self-recursive tail calls. ES2015
 * specified Proper Tail Calls, but no major engine implemented them. So
 * even the simplest tail-recursive accumulator runs as a chain of `call`
 * frames on the engine's stack and overflows around depth ~10_000. `mirror`,
 * `mirrorN`, `deepestLeft{A,B,C}` never get a chance to run.
 */

type Tree<A> =
  | { kind: "Leaf" }
  | { kind: "Node"; left: Tree<A>; value: A; right: Tree<A> };

const LEAF = { kind: "Leaf" as const };

declare const process: { argv: string[] };

function main(): void {
  const treeDepth = Number(process.argv[2]);
  const mirrorCount = Number(process.argv[3]);
  console.log(runDemo(treeDepth, mirrorCount));
}

function runDemo(treeDepth: number, mirrorCount: number): number {
  return deepestLeftA(0, mirrorN(mirrorCount, buildTree(treeDepth)));
}

function buildTree(depth: number): Tree<number> {
  const l = buildLeft(depth, depth, LEAF);
  const r = buildRight(depth, depth, LEAF);
  return { kind: "Node", left: l, value: 0, right: r };
}

function buildLeft(depth: number, value: number, acc: Tree<number>): Tree<number> {
  if (depth === 0) {
    return acc;
  }
  return buildLeft(
    depth - 1,
    value - 1,
    { kind: "Node", left: acc, value, right: LEAF },
  ); // tail recursion
}

function buildRight(depth: number, value: number, acc: Tree<number>): Tree<number> {
  if (depth === 0) {
    return acc;
  }
  return buildRight(
    depth - 1,
    value - 1,
    { kind: "Node", left: LEAF, value, right: acc },
  ); // tail recursion
}

function mirror<A>(t: Tree<A>): Tree<A> {
  switch (t.kind) {
    case "Leaf":
      return LEAF;
    case "Node":
      return { kind: "Node", left: mirror(t.right), value: t.value, right: mirror(t.left) }; // multi-child non-tail recursion
  }
}

function mirrorN<A>(times: number, t: Tree<A>): Tree<A> {
  if (times === 0) {
    return t;
  }
  return mirrorN(times - 1, mirror(t)); // tail recursion
}

function deepestLeftA<A>(lastV: A, t: Tree<A>): A {
  switch (t.kind) {
    case "Leaf":
      return lastV;
    case "Node":
      return deepestLeftB(t.value, t.left); // 3-node mutual tail recursion
  }
}

function deepestLeftB<A>(lastV: A, t: Tree<A>): A {
  switch (t.kind) {
    case "Leaf":
      return lastV;
    case "Node":
      return deepestLeftC(t.value, t.left); // 3-node mutual tail recursion
  }
}

function deepestLeftC<A>(lastV: A, t: Tree<A>): A {
  switch (t.kind) {
    case "Leaf":
      return lastV;
    case "Node":
      return deepestLeftA(t.value, t.left); // 3-node mutual tail recursion
  }
}

main();
