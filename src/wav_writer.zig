//! WAV file writer - writes processed audio to WAV files
const std = @import("std");

pub const Error = error{
    WriteFailed,
} || std.fs.File.WriteError;

pub const WavConfig = struct {
    channels: u16 = 1,
    sample_rate: u32 = 48000,
    bits_per_sample: u16 = 16,
};

fn writeU16LE(file: std.fs.File, value: u16) Error!void {
    var bytes: [2]u8 = undefined;
    std.mem.writeInt(u16, &bytes, value, .little);
    try file.writeAll(&bytes);
}

fn writeI16LE(file: std.fs.File, value: i16) Error!void {
    var bytes: [2]u8 = undefined;
    std.mem.writeInt(i16, &bytes, value, .little);
    try file.writeAll(&bytes);
}

fn writeU32LE(file: std.fs.File, value: u32) Error!void {
    var bytes: [4]u8 = undefined;
    std.mem.writeInt(u32, &bytes, value, .little);
    try file.writeAll(&bytes);
}

fn writeI32LE(file: std.fs.File, value: i32) Error!void {
    var bytes: [4]u8 = undefined;
    std.mem.writeInt(i32, &bytes, value, .little);
    try file.writeAll(&bytes);
}

/// Soft clip (tanh-like saturation) to prevent clipping distortion
fn softClip(sample: f32) f32 {
    // Simple soft clipping using saturation
    if (sample > 1.0) {
        return 1.0;
    } else if (sample < -1.0) {
        return -1.0;
    }
    return sample;
}

/// Write WAV file header and samples
pub fn writeSamples(
    file: std.fs.File,
    config: WavConfig,
    samples: []const f32,
) Error!void {
    const num_samples = samples.len;
    const bytes_per_sample = config.bits_per_sample / 8;
    const block_align = config.channels * bytes_per_sample;
    const byte_rate = config.sample_rate * block_align;
    const data_size = num_samples * bytes_per_sample;
    const file_size = 36 + data_size;

    // Write RIFF header
    try file.writeAll("RIFF");
    try writeU32LE(file, @as(u32, @intCast(file_size)));
    try file.writeAll("WAVE");

    // Write fmt chunk
    try file.writeAll("fmt ");
    try writeU32LE(file, 16); // subchunk size (PCM)
    try writeU16LE(file, 1); // audio format (PCM)
    try writeU16LE(file, config.channels);
    try writeU32LE(file, config.sample_rate);
    try writeU32LE(file, byte_rate);
    try writeU16LE(file, block_align);
    try writeU16LE(file, config.bits_per_sample);

    // Write data chunk
    try file.writeAll("data");
    try writeU32LE(file, @as(u32, @intCast(data_size)));

    // Write samples
    for (samples) |sample| {
        const clipped = softClip(sample);
        if (config.bits_per_sample == 16) {
            const sample_i16 = @as(i16, @intFromFloat(clipped * 32767.0));
            try writeI16LE(file, sample_i16);
        } else if (config.bits_per_sample == 24) {
            const sample_i32 = @as(i32, @intFromFloat(clipped * 8388607.0));
            const sample_u32 = @as(u32, @bitCast(sample_i32));
            var bytes: [3]u8 = undefined;
            bytes[0] = @truncate(sample_u32);
            bytes[1] = @truncate(sample_u32 >> 8);
            bytes[2] = @truncate(sample_u32 >> 16);
            try file.writeAll(&bytes);
        } else if (config.bits_per_sample == 32) {
            const sample_i32 = @as(i32, @intFromFloat(clipped * 2147483647.0));
            try writeI32LE(file, sample_i32);
        }
    }
}
