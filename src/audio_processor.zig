//! Audio processing pipeline - coordinates model and I/O
const std = @import("std");
const nam = @import("nam.zig");
const ir = @import("ir.zig");
const wav_reader = @import("wav_reader.zig");
const wav_writer = @import("wav_writer.zig");
const nam_ffi = @import("nam_ffi.zig");

pub const Error = error{
    InvalidInput,
    ProcessingFailed,
} || wav_reader.Error || wav_writer.Error;

pub const Processor = struct {
    model: nam.Model,
    convolver: ?ir.Convolver = null,
    allocator: std.mem.Allocator,
    buffer_size: u32 = 4096,

    pub fn init(allocator: std.mem.Allocator, model_path: []const u8) !Processor {
        const model = try nam.Model.load(allocator, model_path);
        return Processor{
            .model = model,
            .allocator = allocator,
        };
    }

    /// Initialize with both NAM model and IR
    pub fn initWithIR(allocator: std.mem.Allocator, model_path: []const u8, ir_path: []const u8) !Processor {
        const model = try nam.Model.load(allocator, model_path);
        const ir_obj = try ir.IR.load(allocator, ir_path);
        const convolver = try ir.Convolver.init(allocator, ir_obj);

        return Processor{
            .model = model,
            .convolver = convolver,
            .allocator = allocator,
        };
    }

    pub fn deinit(self: *Processor) void {
        self.model.deinit();
        if (self.convolver) |*conv| {
            conv.deinit();
            // Also free the IR inside the convolver
            var ir_obj = conv.ir;
            ir_obj.deinit();
        }
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

        // Read all samples (as f32 from WAV)
        const input_samples_f32 = try wav_reader.readSamples(input_file, self.allocator, header);
        defer self.allocator.free(input_samples_f32);

        std.debug.print("Loaded {} samples\n", .{input_samples_f32.len});

        // Convert input samples to f64 (NAM_SAMPLE type)
        const input_samples = try self.allocator.alloc(f64, input_samples_f32.len);
        defer self.allocator.free(input_samples);
        for (input_samples_f32, 0..) |sample, i| {
            input_samples[i] = @as(f64, @floatCast(sample));
        }

        // Allocate output buffer (use f64 to match NAM_SAMPLE type)
        const output_samples = try self.allocator.alloc(f64, input_samples.len);
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

            // Process chunk through NAM model
            self.model.process(input_chunk, output_chunk);

            // Apply IR convolution if available
            if (self.convolver) |*conv| {
                const ir_output = try self.allocator.alloc(f64, chunk_size);
                defer self.allocator.free(ir_output);
                conv.process(output_chunk, ir_output);
                @memcpy(output_chunk, ir_output);
            }

            sample_idx += chunk_size;

            // Progress indicator
            if (sample_idx % (header.sample_rate) == 0) {
                const seconds = sample_idx / header.sample_rate;
                std.debug.print("  Processed {} seconds ({}/{})\n", .{ seconds, sample_idx, input_samples.len });
            }
        }

        std.debug.print("Completed processing\n", .{});

        // Convert output samples back to f32 for WAV output
        const output_samples_f32 = try self.allocator.alloc(f32, output_samples.len);
        defer self.allocator.free(output_samples_f32);
        for (output_samples, 0..) |sample, i| {
            output_samples_f32[i] = @as(f32, @floatCast(sample));
        }

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

        try wav_writer.writeSamples(output_file, output_config, output_samples_f32);

        std.debug.print("Written {} samples to {s}\n", .{ output_samples_f32.len, output_path });
    }
};
