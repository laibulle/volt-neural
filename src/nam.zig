//! High-level Zig interface to NAM DSP models
const std = @import("std");
const nam_ffi = @import("nam_ffi.zig");

pub const Error = error{
    FileNotFound,
    InvalidModel,
    LoadFailed,
    NullPointer,
};

pub const Model = struct {
    dsp: *nam_ffi.NamDSP,
    expected_sample_rate: f64,

    /// Load a NAM model from a .nam file
    pub fn load(allocator: std.mem.Allocator, path: []const u8) Error!Model {
        _ = allocator; // We'll allocate internally in C++

        // Convert path to null-terminated string
        var path_buf: [1024]u8 = undefined;
        if (path.len >= 1024) {
            return Error.InvalidModel;
        }
        @memcpy(path_buf[0..path.len], path);
        path_buf[path.len] = 0;

        const dsp = nam_ffi.loadModel(path_buf[0..path.len :0]);
        if (dsp == null) {
            std.debug.print("Error: {s}\n", .{nam_ffi.getLastError()});
            return Error.LoadFailed;
        }

        const sample_rate = nam_ffi.getExpectedSampleRate(dsp);

        return Model{
            .dsp = dsp.?,
            .expected_sample_rate = sample_rate,
        };
    }

    /// Free the model
    pub fn deinit(self: *Model) void {
        nam_ffi.freeModel(self.dsp);
    }

    /// Process audio through the model
    pub fn process(
        self: *Model,
        input: []const nam_ffi.NAM_SAMPLE,
        output: []nam_ffi.NAM_SAMPLE,
    ) void {
        if (input.len != output.len) {
            return;
        }
        nam_ffi.process(self.dsp, input.ptr, output.ptr, @intCast(input.len));
    }

    /// Reset the model state
    pub fn reset(self: *Model, sample_rate: f64, max_buffer_size: u32) void {
        nam_ffi.reset(self.dsp, sample_rate, @intCast(max_buffer_size));
    }

    /// Prewarm the model
    pub fn prewarm(self: *Model) void {
        nam_ffi.prewarm(self.dsp);
    }

    /// Check if model has input level
    pub fn hasInputLevel(self: *Model) bool {
        return nam_ffi.hasInputLevel(self.dsp);
    }

    /// Check if model has output level
    pub fn hasOutputLevel(self: *Model) bool {
        return nam_ffi.hasOutputLevel(self.dsp);
    }

    /// Get input level in dBu
    pub fn getInputLevel(self: *Model) f64 {
        return nam_ffi.getInputLevel(self.dsp);
    }

    /// Get output level in dBu
    pub fn getOutputLevel(self: *Model) f64 {
        return nam_ffi.getOutputLevel(self.dsp);
    }

    /// Get loudness in dB
    pub fn getLoudness(self: *Model) ?f64 {
        if (nam_ffi.hasLoudness(self.dsp)) {
            return nam_ffi.getLoudness(self.dsp);
        }
        return null;
    }
};
