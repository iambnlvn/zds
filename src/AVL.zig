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
                while (currentNode != null) {
                    const balanceFactor = getHeight(currentNode.?.left) - getHeight(currentNode.?.right);
                    const absBalanceFactor = if (balanceFactor < 0) -1 * balanceFactor else balanceFactor;
                    const parent = currentNode.?.parent;
                    if (balanceFactor > 0) {
                        if (absBalanceFactor == 1) {
                            currentNode.?.balance = .left;
                        } else {
                            const leftChild = currentNode.?.left.?;
                            if (data < leftChild.data) {
                                self.rotateRight(currentNode.?);
                            } else {
                                self.rotateLeft(leftChild);
                                self.rotateRight(currentNode.?);
                            }
                        }
                    } else if (balanceFactor < 0) {
                        if (absBalanceFactor == 1) {
                            currentNode.?.balance = .right;
                        } else {
                            const rightChild = currentNode.?.right.?;
                            if (data > rightChild.data) {
                                self.rotateLeft(currentNode.?);
                            } else {
                                self.rotateRight(rightChild);
                                self.rotateLeft(currentNode.?);
                            }
                        }
                    } else {
                        currentNode.?.balance = .balanced;
                    }
                    currentNode = parent;
                }
            }
            if (LogFlag) print("\nInserted {}\n", .{data});
        }

        fn rotateRight(self: *Self, node: *Node) void {
            var parentNode = node.*.parent orelse null;
            const leftChild = node.*.left.?;
            node.*.parent = leftChild;
            leftChild.*.parent = parentNode;

            if (leftChild.*.right) |rightChild| {
                node.*.left = rightChild;
                rightChild.*.parent = node;
            } else {
                node.*.left = null;
            }

            leftChild.*.right = node;
            if (parentNode) |*parent| {
                if (leftChild.*.data > parent.*.data) {
                    parent.*.right = leftChild;
                } else {
                    parent.*.left = leftChild;
                }
            } else {
                self.root = leftChild;
            }
            leftChild.*.balance = .balanced;
            node.*.balance = .balanced;
        }

        fn rotateLeft(self: *Self, node: *Node) void {
            var parentNode = node.*.parent orelse null;
            const rightChild = node.*.right.?;
            node.*.parent = rightChild;
            rightChild.*.parent = parentNode;

            if (rightChild.*.left) |leftChild| {
                node.*.right = leftChild;
                leftChild.*.parent = node;
            } else {
                node.*.right = null;
            }
            rightChild.*.left = node;
            if (parentNode) |*parent| {
                if (rightChild.*.data < parent.*.data) {
                    parent.*.left = rightChild;
                } else {
                    parent.*.right = rightChild;
                }
            } else {
                self.root = rightChild;
            }
            rightChild.*.balance = .balanced;
            node.*.balance = .balanced;
        }

        fn getHeight(node: ?*const Node) isize {
            var currentNode = node orelse return -1;
            var height: isize = 0;
            while (currentNode.*.left != null or currentNode.*.right != null) {
                switch (currentNode.*.balance) {
                    .left => {
                        currentNode = currentNode.*.left.?;
                        height += 1;
                    },
                    .right => {
                        currentNode = currentNode.*.right.?;
                        height += 1;
                    },
                    //traversing down the right subtree (if it exists) is necessary to maintain
                    //the binary search tree properties during insertion, deletion, and search operations
                    //and to ensure the AVL tree remains balanced after these operations.
                    .balanced => {
                        if (currentNode.*.right == null) break;
                        currentNode = currentNode.*.right.?;
                        height += 1;
                    },
                }
            }
            if (LogFlag) print("\nHeight of the tree is {}\n", .{height});
            return height;
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
            if (LogFlag) print("\nDestroying node {any}\n", .{node.?.data});
            self.allocator.destroy(node.?);
        }
    };
}

pub fn main() !void {}

test "many elements tree" {
    const allocator = std.testing.allocator;
    const expect = std.testing.expect;
    var tree = AVL(usize).init(allocator);
    defer tree.deinit();
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

test "insert with rotateRight trigger" {
    const allocator = std.testing.allocator;
    const expect = std.testing.expect;
    var tree = AVL(usize).init(allocator);
    defer tree.deinit();
    try tree.insert(5);
    try tree.insert(7);
    try tree.insert(8);
    try tree.insert(9);
    try tree.insert(10);
    try expect(tree.count == 5);
    print("\nRoot: {any}\n", .{tree.root.?.data});
    try expect(tree.root.?.data == 7);
}

test "insert with rotateLeft trigger" {
    const allocator = std.testing.allocator;
    const expect = std.testing.expect;
    var tree = AVL(usize).init(allocator);
    defer tree.deinit();
    try tree.insert(5);
    try tree.insert(3);
    try tree.insert(2);
    try tree.insert(1);
    try expect(tree.count == 4);
    try expect(tree.root.?.data == 3);
}

test "tree insertions" {
    const allocator = std.testing.allocator;
    const expect = std.testing.expect;
    var tree = AVL(usize).init(allocator);
    defer tree.deinit();
    try tree.insert(5);
    try tree.insert(4);
    try tree.insert(3);
    try tree.insert(2);
    try tree.insert(1);
    try tree.insert(6);
    try tree.insert(7);
    try tree.insert(8);
    try tree.insert(9);
    try tree.insert(10);
    try expect(tree.count == 10);
    try expect(tree.root.?.data == 4);
}
