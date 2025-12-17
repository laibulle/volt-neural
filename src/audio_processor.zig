//! Audio processing pipeline - coordinates model and I/O
const std = @import("std");
const nam = @import("nam.zig");
const wav_reader = @import("wav_reader.zig");
const wav_writer = @import("wav_writer.zig");
const nam_ffi = @import("nam_ffi.zig");

pub const Error = error{
    InvalidInput,
    ProcessingFailed,
} || wav_reader.Error || wav_writer.Error;

pub const Processor = struct {
    model: nam.Model,
    allocator: std.mem.Allocator,
    buffer_size: u32 = 4096,

    pub fn init(allocator: std.mem.Allocator, model_path: []const u8) !Processor {
        const model = try nam.Model.load(allocator, model_path);
        return Processor{
            .model = model,
            .allocator = allocator,
        };
    }

    pub fn deinit(self: *Processor) void {
        self.model.deinit();
    }

    /// Process WAV file through model
    pub fn processFile(
        self: *Processor,
        input_path: []const u8,
        output_path: []const u8,
    ) Error!void {
        // Open input file
        var input_file = std.fs.cwd().openFile(input_path, .{}) catch |err| {
            std.debug.print("Failed to open input file: {}\n", .{err});
            return Error.InvalidInput;
        };
        defer input_file.close();

        // Read WAV header
        const header = try wav_reader.readHeader(input_file);

        std.debug.print("Input WAV: {} channels, {} Hz, {} bits, {} samples\n", .{
            header.channels,
            header.sample_rate,
            header.bits_per_sample,
            header.num_samples,
        });

        // Read all samples
        const input_samples = try wav_reader.readSamples(input_file, self.allocator, header);
        defer self.allocator.free(input_samples);

        std.debug.print("Loaded {} samples\n", .{input_samples.len});

        // Allocate output buffer
        const output_samples = try self.allocator.alloc(f32, input_samples.len);
        defer self.allocator.free(output_samples);

        // Reset model for this sample rate and buffer size
        self.model.reset(
            @as(f64, @floatFromInt(header.sample_rate)),
            self.buffer_size,
        );

        std.debug.print("Model sample rate: {} Hz\n", .{self.model.expected_sample_rate});

        // Prewarm the model
        self.model.prewarm();

        // Process audio in chunks
        std.debug.print("Processing audio...\n", .{});
        var sample_idx: u32 = 0;
        while (sample_idx < input_samples.len) {
            const chunk_size = @min(self.buffer_size, @as(u32, @intCast(input_samples.len - sample_idx)));

            const input_chunk = input_samples[sample_idx .. sample_idx + chunk_size];
            const output_chunk = output_samples[sample_idx .. sample_idx + chunk_size];

            // Process chunk through model
            self.model.process(input_chunk, output_chunk);

            sample_idx += chunk_size;

            // Progress indicator
            if (sample_idx % (header.sample_rate) == 0) {
                const seconds = sample_idx / header.sample_rate;
                std.debug.print("  Processed {} seconds ({}/{})\n", .{ seconds, sample_idx, input_samples.len });
            }
        }

        std.debug.print("Completed processing\n", .{});

        // Write output file
        const output_file = std.fs.cwd().createFile(output_path, .{}) catch |err| {
            std.debug.print("Failed to create output file: {}\n", .{err});
            return Error.InvalidInput;
        };
        defer output_file.close();

        const output_config = wav_writer.WavConfig{
            .channels = header.channels,
            .sample_rate = header.sample_rate,
            .bits_per_sample = header.bits_per_sample,
        };

        try wav_writer.writeSamples(output_file, output_config, output_samples);

        std.debug.print("Written {} samples to {s}\n", .{ output_samples.len, output_path });
    }
};
