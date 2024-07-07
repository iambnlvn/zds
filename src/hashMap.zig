const std = @import("std");
const Allocator = std.mem.Allocator;
const eql = std.mem.eql;

const Entry = struct {
    key: []const u8,
    value: u64,
    next: ?*Entry,
};

const HashMap = struct {
    allocator: std.mem.Allocator,
    table: []?*Entry,

    pub fn init(allocator: Allocator, size: usize) HashMap {
        return HashMap{ .allocator = allocator, .table = allocator.alloc(?*Entry, size) catch unreachable };
    }
    pub fn deinit(self: *HashMap) void {
        for (self.table) |entryPtr| {
            var entry = entryPtr;
            while (entry) |e| {
                const next = e.next;
                self.allocator.free(e);
                entry = next;
            }
        }
        self.allocator.free(self.table);
    }

    fn hash(key: []const u8, size: usize) usize {
        const hasher = std.hash.Fnv1a_64.hash(key);
        return hasher % size;
    }
    pub fn put(self: *HashMap, key: []const u8, value: u64) void {
        const idx = hash(key, self.table.len);
        const newEntry = self.allocator.create(Entry) catch unreachable;
        newEntry.* = Entry{ .key = key, .value = value, .next = self.table[idx] };
        self.table[idx] = newEntry;
    }
    pub fn get(self: *HashMap, key: []const u8) ?u64 {
        const idx = hash(key, self.table.len);
        var entry = self.table[idx];

        while (entry) |e| {
            if (eql(u8, e.key, key)) {
                return e.value;
            }
            entry = e.next;
        }
        return null;
    }
    pub fn remove(self: *HashMap, key: []const u8) !bool {
        const idx = hash(key, self.table.len);
        var prevEntry: ?*Entry = null;
        var entry = self.table[idx];
        if (!entry) {
            return false;
        }
        while (entry) |e| {
            if (eql(u8, e.key, key)) {
                if (prevEntry) |p| {
                    p.next = e.next;
                } else {
                    self.table[idx] = e.next;
                }
                self.allocator.free(e);
                return true;
            }
            prevEntry = entry;
            entry = e.next;
        }
        return false;
    }
};
pub fn main() void {}
