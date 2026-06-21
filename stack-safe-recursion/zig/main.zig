// This program builds an immutable tree of depth `treeDepth`, mirrors it
// `mirrorCount` times, and prints the deepest value on the left path. Both are
// read from argv; the recorded run (assert-behavior.sh) passes `5000000 1`.
//
// Zig outcome (zig 0.16.0, `zig run main.zig -- 5000000 1`): Segmentation fault — a stack
// overflow. Zig guarantees tail calls only for an explicit
// `@call(.always_tail, …)`; ordinary recursion like buildLeft gets no TCO
// guarantee, and at depth 5_000_000 its frames overflow the thread stack
// before the first tree is even built. It aborts in every optimization mode:
// Debug and ReleaseSafe print "Segmentation fault at address …" with a
// buildLeft backtrace, ReleaseFast takes a raw SIGSEGV — the optimizer never
// turns this into a loop. Memory is manual (an arena allocator here), but the
// program never reaches the allocation-heavy mirror loop: it dies in buildLeft
// first.

const std = @import("std");

const Tree = union(enum) {
    leaf,
    node: *Node,
};

const Node = struct {
    left: Tree,
    value: i32,
    right: Tree,
};

var alloc: std.mem.Allocator = undefined;

fn newNode(left: Tree, value: i32, right: Tree) *Node {
    const n = alloc.create(Node) catch @panic("out of memory");
    n.* = .{ .left = left, .value = value, .right = right };
    return n;
}

fn buildLeft(depth: i32, value: i32, acc: Tree) Tree {
    if (depth == 0) return acc;
    return buildLeft(depth - 1, value - 1, .{ .node = newNode(acc, value, .leaf) }); // tail recursion
}

fn buildRight(depth: i32, value: i32, acc: Tree) Tree {
    if (depth == 0) return acc;
    return buildRight(depth - 1, value - 1, .{ .node = newNode(.leaf, value, acc) }); // tail recursion
}

fn buildTree(depth: i32) Tree {
    const l = buildLeft(depth, depth, .leaf);
    const r = buildRight(depth, depth, .leaf);
    return .{ .node = newNode(l, 0, r) };
}

fn mirror(t: Tree) Tree {
    return switch (t) {
        .leaf => .leaf,
        .node => |p| .{ .node = newNode(mirror(p.right), p.value, mirror(p.left)) }, // multi-child non-tail recursion
    };
}

fn mirrorN(times: i32, t: Tree) Tree {
    if (times == 0) return t;
    return mirrorN(times - 1, mirror(t)); // tail recursion
}

fn deepestLeftA(lastV: i32, t: Tree) i32 {
    return switch (t) {
        .leaf => lastV,
        .node => |p| deepestLeftB(p.value, p.left), // 3-node mutual tail recursion
    };
}

fn deepestLeftB(lastV: i32, t: Tree) i32 {
    return switch (t) {
        .leaf => lastV,
        .node => |p| deepestLeftC(p.value, p.left), // 3-node mutual tail recursion
    };
}

fn deepestLeftC(lastV: i32, t: Tree) i32 {
    return switch (t) {
        .leaf => lastV,
        .node => |p| deepestLeftA(p.value, p.left), // 3-node mutual tail recursion
    };
}

fn runDemo(tree_depth: i32, mirror_count: i32) i32 {
    return deepestLeftA(0, mirrorN(mirror_count, buildTree(tree_depth)));
}

pub fn main(init: std.process.Init) !void {
    alloc = init.arena.allocator();
    const argv = try init.minimal.args.toSlice(alloc);
    const tree_depth = try std.fmt.parseInt(i32, argv[1], 10);
    const mirror_count = try std.fmt.parseInt(i32, argv[2], 10);
    const result = runDemo(tree_depth, mirror_count);
    var buf: [64]u8 = undefined;
    var w = std.Io.File.stdout().writer(init.io, &buf);
    const out = &w.interface;
    try out.print("{d}\n", .{result});
    try out.flush();
}
