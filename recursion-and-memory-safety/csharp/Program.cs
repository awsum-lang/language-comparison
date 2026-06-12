/* This demo program builds an immutable tree of depth 100_000, mirrors it 500
 * times (causing heavy allocation pressure), and displays the deepest value on
 * the left path.
 *
 * C# outcome (.NET SDK 10.0.105, `dotnet run -c Release`): `Stack overflow.`
 * process abort inside `Mirror` on the very first call. Roslyn never emits
 * the CIL `tail.` prefix (unlike F#), and RyuJIT does not rewrite
 * BuildLeft's self-tail call into a loop either (verified separately: the
 * same BuildLeft at depth 10_000_000 dies inside BuildLeft) — every
 * recursion here, tail or not, consumes stack linear in depth. BuildLeft
 * survives this scenario's depth 100_000 only because ~100k frames happen
 * to fit in the main thread's ~8 MB stack on macOS; Mirror's first descent
 * under the default tiered JIT does not fit, and the runtime aborts.
 *
 * With tiered compilation disabled (DOTNET_TieredCompilation=0) every
 * method gets small fully-optimized frames from its first call, and this
 * exact depth squeezes through end to end — the program prints 100000.
 * The frame size of the JIT tier is the difference between crashing and
 * finishing; that is luck, not recursion safety. Stack use stays linear
 * in depth, so a deeper tree (or Windows' smaller default main stack)
 * kills the same code again.
 */

using System.Diagnostics;

Console.WriteLine(Demo.Run());

static class Demo
{
    internal static int Run() => DeepestLeftA(0, MirrorN(500, BuildTree(100_000)));

    static Tree<int> BuildTree(int depth)
    {
        Tree<int> l = BuildLeft(depth, depth, new Leaf<int>());
        Tree<int> r = BuildRight(depth, depth, new Leaf<int>());
        return new Node<int>(l, 0, r);
    }

    static Tree<int> BuildLeft(int depth, int value, Tree<int> acc) =>
        depth == 0
            ? acc
            : BuildLeft(depth - 1, value - 1, new Node<int>(acc, value, new Leaf<int>())); // tail recursion

    static Tree<int> BuildRight(int depth, int value, Tree<int> acc) =>
        depth == 0
            ? acc
            : BuildRight(depth - 1, value - 1, new Node<int>(new Leaf<int>(), value, acc)); // tail recursion

    static Tree<A> Mirror<A>(Tree<A> t) => t switch
    {
        Leaf<A> => t,
        Node<A>(var l, var v, var r) => new Node<A>(Mirror(r), v, Mirror(l)), // multi-child non-tail recursion
        _ => throw new UnreachableException(), // the checker cannot know the hierarchy is closed
    };

    static Tree<A> MirrorN<A>(int times, Tree<A> t) =>
        times == 0
            ? t
            : MirrorN(times - 1, Mirror(t)); // tail recursion + heavy allocation pressure

    static A DeepestLeftA<A>(A lastV, Tree<A> t) => t switch
    {
        Leaf<A> => lastV,
        Node<A>(var l, var v, _) => DeepestLeftB(v, l), // 3-node mutual tail recursion
        _ => throw new UnreachableException(),
    };

    static A DeepestLeftB<A>(A lastV, Tree<A> t) => t switch
    {
        Leaf<A> => lastV,
        Node<A>(var l, var v, _) => DeepestLeftC(v, l), // 3-node mutual tail recursion
        _ => throw new UnreachableException(),
    };

    static A DeepestLeftC<A>(A lastV, Tree<A> t) => t switch
    {
        Leaf<A> => lastV,
        Node<A>(var l, var v, _) => DeepestLeftA(v, l), // 3-node mutual tail recursion
        _ => throw new UnreachableException(),
    };
}

abstract record Tree<A>;

sealed record Leaf<A> : Tree<A>;

sealed record Node<A>(Tree<A> Left, A Value, Tree<A> Right) : Tree<A>;
