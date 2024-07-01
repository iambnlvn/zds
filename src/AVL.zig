const std = @import("std");
const print = std.debug.print;

const LogFlag = false; // controls whether to print debug logs

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
                const left = if (self.left) self.left.?.data else null;
                const right = if (self.left) self.right.?.data else null;
                print("\nData: {any}, Parent: {any}, Left: {any}, Right: {r}\n", .{ data, parent, left, right });
            }
        };
        fn init(allocator: std.mem.Allocator) Self {
            return AVL(T){ .root = null, .count = 0, .allocator = allocator };
        }

        fn createNode(self: *Self, data: T, parent: ?*Node) !*Node {
            const newNode = (try self.*.allocator.create(Node)).*.init(data, parent);
            self.*.count += 1;
            return newNode;
        }
        fn insert(self: *Self, data: T) !void {
            if (self.root == null) {
                self.root = try self.createNode(data, null);
            } else {
                var currentNode = self.root;
                while (currentNode) |*node| {
                    if (data < node.*.data) {
                        if (node.*.left == null) {
                            if (LogFlag) print("\nInserting {} at the left of {}", .{ data, node.*.data });
                            node.*.left = try createNode(data, node.*);
                            break;
                        } else {
                            currentNode = node.*.left;
                            continue;
                        }
                    } else if (data > node.*.data) {
                        if (node.*.right == null) {
                            if (LogFlag) print("\nInserting {} at the right of {}", .{ data, node.*.data });
                            node.*.right = try createNode(data, node.*);
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
    };
}
