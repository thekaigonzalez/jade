//! VJSection
//! Contains the structure of a VOLT Section, primarily designed for subroutine caching
//! 32-bit VM (JADE), for 8-bit VM (JADE)

// $Id: VJSection.zig

pub const jade_Section = struct {
    data: [256]i32,
    label: i32 = 0,

    pub fn create() jade_Section {
        return jade_Section{ .data = [_]i32{0} ** 256 };
    }

    /// Sets the label of the section
    pub fn setlab(self: *jade_Section, label: i32) void {
        self.label = label;
    }

    /// Write DATA to section
    pub fn write(self: *jade_Section, data: []i32) void {
        for (0..data.len) |i| {
            self.data[i] = data[i];
        }
    }

    /// Read DATA from section
    pub fn read(self: *jade_Section) []i32 {
        return &self.data;
    }
};
