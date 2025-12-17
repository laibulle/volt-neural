//! IR (Impulse Response) loader and convolution processor
const std = @import("std");
const wav_reader = @import("wav_reader.zig");

pub const Error = error{
    InvalidIR,
    AllocFailed,
    LoadFailed,
} || wav_reader.Error;

pub const IR = struct {
    /// Impulse response samples (normalized -1 to 1)
    samples: []f64,
    sample_rate: u32,
    allocator: std.mem.Allocator,

    /// Load an IR from a WAV file
    pub fn load(allocator: std.mem.Allocator, path: []const u8) Error!IR {
        var file = std.fs.cwd().openFile(path, .{}) catch |err| {
            std.debug.print("Failed to open IR file: {}\n", .{err});
            return Error.LoadFailed;
        };
        defer file.close();

        // Read WAV header
        const header = try wav_reader.readHeader(file);

        // Read samples as f32
        const samples_f32 = try wav_reader.readSamples(file, allocator, header);
        defer allocator.free(samples_f32);

        std.debug.print("Loaded IR: {} samples at {} Hz ({} channels)\n", .{
            header.num_samples,
            header.sample_rate,
            header.channels,
        });

        // Convert to f64 and mix down to mono if needed
        const ir_samples = try allocator.alloc(f64, header.num_samples);
        errdefer allocator.free(ir_samples);

        if (header.channels == 1) {
            // Already mono
            for (samples_f32, 0..) |sample, i| {
                ir_samples[i] = @as(f64, @floatCast(sample));
            }
        } else {
            // Mix down to mono by averaging channels
            const samples_per_channel = header.num_samples / header.channels;
            for (0..samples_per_channel) |i| {
                var sum: f64 = 0.0;
                for (0..header.channels) |ch| {
                    const sample = samples_f32[i * header.channels + ch];
                    sum += @as(f64, @floatCast(sample));
                }
                ir_samples[i] = sum / @as(f64, @floatFromInt(header.channels));
            }
        }

        return IR{
            .samples = ir_samples,
            .sample_rate = header.sample_rate,
            .allocator = allocator,
        };
    }

    /// Free the IR
    pub fn deinit(self: *IR) void {
        self.allocator.free(self.samples);
    }

    /// Get IR length in samples
    pub fn len(self: IR) usize {
        return self.samples.len;
    }
};

pub const Convolver = struct {
    ir: IR,
    history: []f64,
    history_pos: u32,
    allocator: std.mem.Allocator,

    /// Create a convolver with an IR
    pub fn init(allocator: std.mem.Allocator, ir: IR) Error!Convolver {
        const history = try allocator.alloc(f64, ir.len());
        errdefer allocator.free(history);

        // Initialize history to zero
        @memset(history, 0.0);

        return Convolver{
            .ir = ir,
            .history = history,
            .history_pos = 0,
            .allocator = allocator,
        };
    }

    /// Free the convolver
    pub fn deinit(self: *Convolver) void {
        self.allocator.free(self.history);
    }

    /// Soft clip to prevent internal clipping in convolver
    fn softClip(sample: f64) f64 {
        if (sample > 1.0) {
            return 1.0;
        } else if (sample < -1.0) {
            return -1.0;
        }
        return sample;
    }

    /// Process a chunk of audio through the IR using time-domain convolution
    /// This uses a simple FIR filter approach (partitioned convolution would be faster)
    pub fn process(self: *Convolver, input: []const f64, output: []f64) void {
        std.debug.assert(input.len == output.len);

        const ir_len = self.ir.samples.len;

        for (input, 0..) |sample, i| {
            // Add new sample to history
            self.history[self.history_pos] = sample;

            // Convolve with IR
            var sum: f64 = 0.0;
            for (0..ir_len) |j| {
                const hist_idx = (self.history_pos + ir_len - j) % ir_len;
                sum += self.history[hist_idx] * self.ir.samples[j];
            }

            // Soft clip to prevent internal clipping
            output[i] = softClip(sum);

            // Move to next history position
            self.history_pos = (self.history_pos + 1) % @as(u32, @intCast(ir_len));
        }
    }

    /// Reset the convolver state
    pub fn reset(self: *Convolver) void {
        @memset(self.history, 0.0);
        self.history_pos = 0;
    }
};
