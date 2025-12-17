// Zig FFI bindings to NAM C wrapper
const std = @import("std");
const c = @cImport({
    @cInclude("nam.h");
});

pub const NAM_OK = c.NAM_OK;
pub const NAM_ERR_FILE_NOT_FOUND = c.NAM_ERR_FILE_NOT_FOUND;
pub const NAM_ERR_INVALID_MODEL = c.NAM_ERR_INVALID_MODEL;
pub const NAM_ERR_LOAD_FAILED = c.NAM_ERR_LOAD_FAILED;
pub const NAM_ERR_NULL_POINTER = c.NAM_ERR_NULL_POINTER;

pub const NamDSP = c.NamDSP;
pub const NAM_SAMPLE = c.NAM_SAMPLE;

/// Load a NAM model from a .nam file
/// Returns null on failure
pub fn loadModel(path: [:0]const u8) ?*NamDSP {
    return c.nam_load_model(path);
}

/// Free a loaded NAM model
pub fn freeModel(dsp: *NamDSP) void {
    c.nam_free_model(dsp);
}

/// Process audio through the model
pub fn process(
    dsp: *NamDSP,
    input: [*]const NAM_SAMPLE,
    output: [*]NAM_SAMPLE,
    num_frames: i32,
) void {
    c.nam_process(dsp, input, output, num_frames);
}

/// Reset the DSP state
pub fn reset(dsp: *NamDSP, sample_rate: f64, max_buffer_size: i32) void {
    c.nam_reset(dsp, sample_rate, max_buffer_size);
}

/// Pre-warm the model
pub fn prewarm(dsp: *NamDSP) void {
    c.nam_prewarm(dsp);
}

/// Get expected sample rate
pub fn getExpectedSampleRate(dsp: ?*NamDSP) f64 {
    if (dsp == null) return -1.0;
    return c.nam_get_expected_sample_rate(dsp);
}

/// Check if model has input level information
pub fn hasInputLevel(dsp: ?*NamDSP) bool {
    if (dsp == null) return false;
    return c.nam_has_input_level(dsp) != 0;
}

/// Check if model has output level information
pub fn hasOutputLevel(dsp: ?*NamDSP) bool {
    if (dsp == null) return false;
    return c.nam_has_output_level(dsp) != 0;
}

/// Get input level in dBu
pub fn getInputLevel(dsp: ?*NamDSP) f64 {
    if (dsp == null) return 0.0;
    return c.nam_get_input_level(dsp);
}

/// Get output level in dBu
pub fn getOutputLevel(dsp: ?*NamDSP) f64 {
    if (dsp == null) return 0.0;
    return c.nam_get_output_level(dsp);
}

/// Set input level in dBu
pub fn setInputLevel(dsp: ?*NamDSP, level: f64) void {
    if (dsp == null) return;
    c.nam_set_input_level(dsp, level);
}

/// Set output level in dBu
pub fn setOutputLevel(dsp: ?*NamDSP, level: f64) void {
    if (dsp == null) return;
    c.nam_set_output_level(dsp, level);
}

/// Check if model has loudness information
pub fn hasLoudness(dsp: ?*NamDSP) bool {
    if (dsp == null) return false;
    return c.nam_has_loudness(dsp) != 0;
}

/// Get loudness in dB
pub fn getLoudness(dsp: ?*NamDSP) f64 {
    if (dsp == null) return 0.0;
    return c.nam_get_loudness(dsp);
}

/// Set loudness in dB
pub fn setLoudness(dsp: ?*NamDSP, loudness: f64) void {
    if (dsp == null) return;
    c.nam_set_loudness(dsp, loudness);
}

/// Get the last error message
pub fn getLastError() [*:0]const u8 {
    return c.nam_get_last_error();
}
