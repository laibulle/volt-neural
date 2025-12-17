//! WAV file reader - parses and reads WAV audio files
const std = @import("std");

pub const Error = error{
    InvalidHeader,
    InvalidFormat,
    UnexpectedEOF,
    UnsupportedFormat,
    IOError,
    OutOfMemory,
} || std.fs.File.ReadError;

pub const WavHeader = struct {
    channels: u16,
    sample_rate: u32,
    bits_per_sample: u16,
    num_samples: u32,
    byte_rate: u32,
    block_align: u16,
};

fn readExact(file: std.fs.File, buf: []u8) Error!void {
    const bytes_read = try file.readAll(buf);
    if (bytes_read < buf.len) {
        return Error.UnexpectedEOF;
    }
}

fn readU16LE(file: std.fs.File) Error!u16 {
    var buf: [2]u8 = undefined;
    try readExact(file, &buf);
    return std.mem.bytesToValue(u16, &buf);
}

fn readU32LE(file: std.fs.File) Error!u32 {
    var buf: [4]u8 = undefined;
    try readExact(file, &buf);
    return std.mem.bytesToValue(u32, &buf);
}

fn readI16LE(file: std.fs.File) Error!i16 {
    var buf: [2]u8 = undefined;
    try readExact(file, &buf);
    return std.mem.bytesToValue(i16, &buf);
}

fn readI32LE(file: std.fs.File) Error!i32 {
    var buf: [4]u8 = undefined;
    try readExact(file, &buf);
    return std.mem.bytesToValue(i32, &buf);
}

/// Read WAV file header
pub fn readHeader(file: std.fs.File) Error!WavHeader {

    // Read RIFF header
    var riff_header: [4]u8 = undefined;
    try readExact(file, &riff_header);
    if (!std.mem.eql(u8, &riff_header, "RIFF")) {
        return Error.InvalidHeader;
    }

    // Read file size (we don't really need this)
    _ = try readU32LE(file);

    // Read WAVE marker
    var wave_marker: [4]u8 = undefined;
    try readExact(file, &wave_marker);
    if (!std.mem.eql(u8, &wave_marker, "WAVE")) {
        return Error.InvalidHeader;
    }

    // Find fmt chunk
    var fmt_found = false;
    var fmt_header: WavHeader = undefined;

    while (true) {
        var chunk_id: [4]u8 = undefined;
        const bytes_read = try file.readAll(&chunk_id);
        if (bytes_read < 4) return Error.UnexpectedEOF;

        if (std.mem.eql(u8, &chunk_id, "fmt ")) {
            fmt_found = true;

            // Read subchunk size
            const chunk_size = try readU32LE(file);

            if (chunk_size < 16) {
                return Error.InvalidFormat;
            }

            // Read fmt data
            const audio_format = try readU16LE(file);

            // Only support PCM (format 1)
            if (audio_format != 1) {
                return Error.UnsupportedFormat;
            }

            fmt_header.channels = try readU16LE(file);
            fmt_header.sample_rate = try readU32LE(file);
            fmt_header.byte_rate = try readU32LE(file);
            fmt_header.block_align = try readU16LE(file);
            fmt_header.bits_per_sample = try readU16LE(file);

            // Skip any extra bytes in fmt chunk
            if (chunk_size > 16) {
                const extra = chunk_size - 16;
                var skip_buf: [256]u8 = undefined;
                var remaining = extra;
                while (remaining > 0) {
                    const to_read = @min(remaining, 256);
                    _ = try file.readAll(skip_buf[0..to_read]);
                    remaining -= to_read;
                }
            }
            break;
        } else if (std.mem.eql(u8, &chunk_id, "data")) {
            if (!fmt_found) {
                return Error.InvalidFormat;
            }

            // Read data size
            const data_size = try readU32LE(file);

            // Calculate number of samples
            fmt_header.num_samples = data_size / fmt_header.block_align;
            return fmt_header;
        } else {
            // Skip unknown chunk
            const chunk_size = try readU32LE(file);

            var skip_buf: [256]u8 = undefined;
            var remaining = chunk_size;
            while (remaining > 0) {
                const to_read = @min(remaining, 256);
                _ = try file.readAll(skip_buf[0..to_read]);
                remaining -= to_read;
            }
        }
    }
    return fmt_header;
}

/// Read audio samples from WAV file
pub fn readSamples(
    file: std.fs.File,
    allocator: std.mem.Allocator,
    header: WavHeader,
) Error![]f32 {
    // Allocate buffer for samples
    const samples = try allocator.alloc(f32, header.num_samples);
    errdefer allocator.free(samples);

    var sample_idx: usize = 0;

    // Read samples
    while (sample_idx < header.num_samples) : (sample_idx += 1) {
        if (header.bits_per_sample == 16) {
            const sample_i16 = try readI16LE(file);
            samples[sample_idx] = @as(f32, @floatFromInt(sample_i16)) / 32768.0;
        } else if (header.bits_per_sample == 24) {
            var sample_bytes: [3]u8 = undefined;
            try readExact(file, &sample_bytes);
            var sample_i32: i32 = 0;
            sample_i32 |= @as(i32, sample_bytes[0]);
            sample_i32 |= @as(i32, sample_bytes[1]) << 8;
            const sign_byte = @as(i32, @as(i8, @bitCast(sample_bytes[2])));
            sample_i32 |= sign_byte << 16;
            samples[sample_idx] = @as(f32, @floatFromInt(sample_i32)) / 8388608.0;
        } else if (header.bits_per_sample == 32) {
            const sample_i32 = try readI32LE(file);
            samples[sample_idx] = @as(f32, @floatFromInt(sample_i32)) / 2147483648.0;
        } else {
            return Error.UnsupportedFormat;
        }
    }

    return samples;
}
