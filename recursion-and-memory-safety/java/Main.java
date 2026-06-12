/* This demo program builds an immutable tree of depth 100_000, mirrors it 500
 * times (causing heavy allocation pressure), and displays the deepest value on
 * the left path.
 *
 * Java outcome (OpenJDK 25.0.3, Temurin): `java.lang.StackOverflowError`
 * inside `buildLeft` on the very first call. Neither javac nor HotSpot
 * performs tail-call elimination of any kind — there isn't even Scala's
 * compile-time self-tail-to-loop rewrite — so a plain tail-recursive
 * accumulator runs as a chain of real stack frames. The depth-100_000 left
 * spine exhausts the JVM's default thread stack long before the first tree
 * is built; mirror, mirrorN and deepestLeftA/B/C never get a chance to run.
 * The only mitigation is a bigger -Xss, which moves the cliff without
 * removing it.
 */

public class Main {
    public static void main(String[] args) {
        System.out.println(runDemo());
    }

    static int runDemo() {
        return deepestLeftA(0, mirrorN(500, buildTree(100_000)));
    }

    static Tree<Integer> buildTree(int depth) {
        Tree<Integer> l = buildLeft(depth, depth, new Leaf<>());
        Tree<Integer> r = buildRight(depth, depth, new Leaf<>());
        return new Node<>(l, 0, r);
    }

    static Tree<Integer> buildLeft(int depth, int value, Tree<Integer> acc) {
        if (depth == 0) {
            return acc;
        }
        return buildLeft(depth - 1, value - 1, new Node<>(acc, value, new Leaf<>())); // tail recursion
    }

    static Tree<Integer> buildRight(int depth, int value, Tree<Integer> acc) {
        if (depth == 0) {
            return acc;
        }
        return buildRight(depth - 1, value - 1, new Node<>(new Leaf<>(), value, acc)); // tail recursion
    }

    static <A> Tree<A> mirror(Tree<A> t) {
        if (t instanceof Node<A> n) {
            return new Node<>(mirror(n.right()), n.value(), mirror(n.left())); // multi-child non-tail recursion
        }
        return t; // Leaf
    }

    static <A> Tree<A> mirrorN(int times, Tree<A> t) {
        if (times == 0) {
            return t;
        }
        return mirrorN(times - 1, mirror(t)); // tail recursion + heavy allocation pressure
    }

    static <A> A deepestLeftA(A lastV, Tree<A> t) {
        if (t instanceof Node<A> n) {
            return deepestLeftB(n.value(), n.left()); // 3-node mutual tail recursion
        }
        return lastV; // Leaf
    }

    static <A> A deepestLeftB(A lastV, Tree<A> t) {
        if (t instanceof Node<A> n) {
            return deepestLeftC(n.value(), n.left()); // 3-node mutual tail recursion
        }
        return lastV; // Leaf
    }

    static <A> A deepestLeftC(A lastV, Tree<A> t) {
        if (t instanceof Node<A> n) {
            return deepestLeftA(n.value(), n.left()); // 3-node mutual tail recursion
        }
        return lastV; // Leaf
    }
}

sealed interface Tree<A> permits Leaf, Node {}

record Leaf<A>() implements Tree<A> {}

record Node<A>(Tree<A> left, A value, Tree<A> right) implements Tree<A> {}
