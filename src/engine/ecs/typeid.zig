pub const TypeID = *const Type;

pub const Type = opaque {
    pub const id: fn (comptime T: type) TypeID = struct {
        inline fn tid(comptime T: type) TypeID {
            const TypeIDSlot = struct {
                var slot: u32 = 0;
                comptime {
                    _ = T;
                }
            };
            return @ptrCast(&TypeIDSlot.slot);
        }

        fn typeID(comptime T: type) TypeID {
            return comptime tid(T);
        }
    }.typeID;

    pub fn toInt(self: TypeID) TypeIntID {
        return TypeIntID.from(self);
    }
};

pub const TypeIntID = enum (usize) {
    invalid = 0,
    _,

    pub fn from(tid: Type) TypeIntID {
        return @enumFromInt(@intFromPtr(tid));
    }

    pub fn toType(self: TypeIntID) TypeID {
        return @ptrFromInt(@intFromEnum(self));
    }

    pub fn toPtr(self: TypeIntID) [*]u8 {
        return @ptrFromInt(@intFromEnum(self));
    }
};