# Volt Neural - Real-time Neural Amp Modeler

A high-performance real-time audio processing tool built in **Zig** that chains Neural Amp Models (NAM) with Impulse Response (IR) convolution for authentic amplifier and cabinet simulation.

## Features

- **NAM Core Integration**: Process guitar audio through trained neural network amp models
- **IR Convolution**: Apply cabinet impulse responses with FIR filtering
- **Chainable Processing**: NAM → IR convolution pipeline
- **Flexible I/O**: Support for 16/24/32-bit PCM WAV files, mono and stereo
- **Sample Rate Handling**: Automatic conversion between input and model sample rates
- **Soft Clipping**: Safe handling of signals that exceed normal range

## Building

```bash
zig build
```

## Usage

### NAM Model Only
Process audio through a neural amp model:

```bash
zig build run -- <input.wav> <model.nam> <output.wav>
```

Example:
```bash
zig build run -- samples/guitar/smooth-electric-guitar-chord.wav samples/neural/JCM800.nam zig-out/test.wav samples/ir/CelestionVintage30/48.0kHz/500ms/CenzoCelestionV30Mix.wav
```

### NAM + IR Cabinet (Chained)
Process through amp model, then apply cabinet IR:

```bash
zig build run -- <input.wav> <model.nam> <output.wav> <cabinet.wav>
```

Example:
```bash
zig build run -- samples/guitar/smooth-electric-guitar-chord.wav samples/neural/JCM800.nam zig-out/test.wav samples/ir/CelestionVintage30/48.0kHz/200ms/CenzoCelestionV30Mix.wav
```

## Architecture

### Modules

- **nam.zig**: High-level interface to NAM models
- **nam_ffi.zig**: Zig FFI bindings to C wrapper
- **nam_wrapper.cpp**: C++ wrapper bridging to NAM Core library
- **ir.zig**: IR loading and convolution processor
- **wav_reader.zig**: WAV file parser (RIFF/PCM formats)
- **wav_writer.zig**: WAV file writer with soft clipping
- **audio_processor.zig**: Main processing pipeline (NAM → IR → Output)
- **main.zig**: CLI interface

### Processing Pipeline

1. **Input**: Load guitar audio from WAV file
2. **Model**: Process through NAM neural network
3. **Convolution**: (Optional) Apply cabinet IR via FIR filter
4. **Output**: Write processed audio to WAV file with soft clipping

## Dependencies

- **NeuralAmpModelerCore**: Neural amp modeling library (submodule)
- **Eigen**: Matrix/vector library (header-only, included)
- **nlohmann/json**: JSON parsing (header-only, included)

## Sample Files

- **Amp Models** (`samples/neural/`):
  - `JCM800.nam` - Marshall JCM800 amp model
  - `EVH5150Iconic80W-Channel2.nam` - EVH 5150 amp model

- **Cabinet IRs** (`samples/ir/CelestionVintage30/`):
  - Multiple sample rates: 44.1kHz, 48kHz, 88.2kHz, 96kHz
  - Multiple lengths: 200ms, 500ms
  - Celestion Vintage 30" speaker impulse response

- **Guitar Input** (`samples/guitar/`):
  - `smooth-electric-guitar-chord.wav` - Test audio file

## Technical Details

### NAM Processing
- Loads `.nam` model files containing neural network weights
- Processes audio in configurable chunks (default 4096 samples)
- Handles sample rate conversion between input and model expectations
- Provides model metadata (loudness, level information)

### IR Convolution
- Loads cabinet impulse responses from WAV files
- Uses time-domain FIR filtering (partitioned convolution could improve performance)
- Automatically mixes multi-channel IRs to mono
- Processes in real-time with circular buffer

### Audio Format Support
- PCM 16-bit: Full support
- PCM 24-bit: Full support  
- PCM 32-bit: Full support
- Mono/Stereo: Full support
- Variable sample rates: Supported (44.1kHz, 48kHz, etc.)
- LIST chunks: Properly handled between fmt and data chunks

### Signal Processing
- Sample type: `f64` (double precision) throughout processing
- Dynamic range: [-1.0, 1.0] normalized
- Soft clipping: Applied during write to prevent distortion from IR amplification
- Precision: 64-bit floating point maintains quality through full chain
