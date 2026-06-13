/* This demo program builds an immutable tree of depth 300_000, mirrors it 500
 * times (causing heavy allocation pressure), and displays the deepest value on
 * the left path.
 *
 * C# outcome (.NET SDK 10.0.105, `dotnet run -c Release`): `Stack overflow.`
 * process abort, no output. Roslyn never emits the CIL `tail.` prefix
 * (unlike F#, whose compiler turns self-tail calls into IL loops), so
 * nothing here is guaranteed stack-safe.
 *
 * Under the default tiered JIT, BuildLeft's plain tail recursion is a race:
 * its tier-0 frames pile up linearly on the stack while the optimizing tier
 * tries to rewrite the self-call into a loop. Which side wins — and so which
 * function the process dies in — shifts with platform, depth, and run. It
 * has been observed aborting inside BuildLeft (macOS at every depth tried;
 * the Linux runner at depth 500_000) and inside Mirror, ~150k frames into
 * the non-tail recursion no JIT trick can flatten (the Linux runner at depth
 * 300_000). With DOTNET_TieredCompilation=0 BuildLeft is loop-rewritten from
 * its first call and the crash is always in Mirror.
 *
 * The constant across every platform, depth, and configuration is the
 * `Stack overflow.` abort before any output — which is what the entry
 * asserts, not the function it happens to die in.
 */

using System.Diagnostics;

Console.WriteLine(Demo.Run());

static class Demo
{
    internal static int Run() => DeepestLeftA(0, MirrorN(500, BuildTree(300_000)));

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
