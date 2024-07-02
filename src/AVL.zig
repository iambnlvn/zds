const std = @import("std");
const print = std.debug.print;

const LogFlag = true; // controls whether to print debug logs

fn AVL(comptime T: type) type {
    return struct {
        const Balance = enum { left, right, balanced };
        const Self = @This();
        allocator: std.mem.Allocator,
        root: ?*Node,
        count: usize,
        const Node = struct {
            data: T,
            parent: ?*Node,
            left: ?*Node,
            right: ?*Node,
            balance: Balance,

            fn init(self: *Node, data: T, parent: ?*Node) void {
                self.data = data;
                self.parent = parent orelse null;
                self.left = null;
                self.right = null;
                self.balance = .balanced;
            }
            fn printNode(self: Node) void {
                const data = self.data;
                const parent = if (self.parent != null) self.parent.?.data else null;
                const left = if (self.left != null) self.left.?.data else null;
                const right = if (self.right != null) self.right.?.data else null;
                print("\nData: {any}, Parent: {any}, Left: {any}, Right: {any}\n", .{ data, parent, left, right });
            }
        };
        fn init(allocator: std.mem.Allocator) Self {
            return AVL(T){ .root = null, .count = 0, .allocator = allocator };
        }

        fn createNode(self: *Self, data: T, parent: ?*Node) !*Node {
            const newNode = try self.*.allocator.create(Node);
            newNode.*.init(data, parent);
            self.*.count += 1;
            return newNode;
        }
        fn insert(self: *Self, data: T) !void {
            if (self.root == null) {
                self.root = try self.createNode(data, null);
                if (LogFlag) print("\nInserting {} as root\n", .{data});
            } else {
                var currentNode = self.root;
                while (currentNode) |*node| {
                    if (data < node.*.data) {
                        if (node.*.left == null) {
                            if (LogFlag) print("\nInserting {} at the left of {}", .{ data, node.*.data });
                            node.*.left = try self.createNode(data, node.*);
                            break;
                        } else {
                            currentNode = node.*.left;
                            continue;
                        }
                    } else if (data > node.*.data) {
                        if (node.*.right == null) {
                            if (LogFlag) print("\nInserting {} at the right of {}", .{ data, node.*.data });
                            node.*.right = try self.createNode(data, node.*);
                            break;
                        } else {
                            currentNode = node.*.right;
                            continue;
                        }
                    } else {
                        print("\nData: {} already exists in the tree\n", .{data});
                        break;
                    }
                }
            }
        }
        fn deinit(self: Self) void {
            if (LogFlag) print("\nDeinitializing AVL Tree\n", .{});
            self.deinitNode(self.root);
        }

        fn deinitNode(self: Self, node: ?*Node) void {
            if (node == null) return;
            self.deinitNode(node.?.left);
            self.deinitNode(node.?.right);
            if (node.?.parent != null) {
                const p = node.?.parent.?;
                if (p.left == node) {
                    p.left = null;
                } else if (p.right == node) {
                    p.right = null;
                }
            }
            print("\nDestroying node {any}\n", .{node.?.data});
            self.allocator.destroy(node.?);
        }
    };
}

pub fn main() !void {}

test "many elements tree" {
    //this will create a memory leak as no deinitalization is done
    const allocator = std.testing.allocator;
    const expect = std.testing.expect;
    var tree = AVL(usize).init(allocator);
    try tree.insert(10);
    try tree.insert(21);
    try expect(tree.count == 2);
}

test "deinit" {
    const allocator = std.testing.allocator;
    var tree = AVL(usize).init(allocator);
    try tree.insert(11);
    tree.deinit();
}
test "insert" {
    const allocator = std.testing.allocator;
    const expect = std.testing.expect;
    var tree = AVL(usize).init(allocator);
    defer tree.deinit();
    try tree.insert(13);
    try tree.insert(12);
    try tree.insert(9);
    try tree.insert(2);
    try tree.insert(2002);
    try tree.insert(11);
    try tree.insert(1);
    try expect(tree.count == 7);
}
