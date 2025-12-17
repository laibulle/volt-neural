#ifndef NAM_FFI_WRAPPER_H
#define NAM_FFI_WRAPPER_H

#include <stdint.h>
#include <stddef.h>

#ifdef __cplusplus
extern "C" {
#endif

// Opaque handle to nam::DSP instance
typedef struct {
    void* ptr;
} NamDSP;

// Audio sample type (double - must match NAM library)
typedef double NAM_SAMPLE;

// Function return codes
typedef int32_t NamResult;
#define NAM_OK 0
#define NAM_ERR_FILE_NOT_FOUND -1
#define NAM_ERR_INVALID_MODEL -2
#define NAM_ERR_LOAD_FAILED -3
#define NAM_ERR_NULL_POINTER -4

// Load a .nam model file and return a DSP instance
// Returns NULL on failure; check errno or use get_last_error()
NamDSP* nam_load_model(const char* model_path);

// Free a DSP instance
void nam_free_model(NamDSP* dsp);

// Process audio
// num_frames: number of samples to process
void nam_process(NamDSP* dsp, const NAM_SAMPLE* input, NAM_SAMPLE* output, int32_t num_frames);

// Reset the DSP state
// sample_rate: expected sample rate in Hz
// max_buffer_size: maximum buffer size for processing
void nam_reset(NamDSP* dsp, double sample_rate, int32_t max_buffer_size);

// Pre-warm the model (settle initial conditions)
void nam_prewarm(NamDSP* dsp);

// Get expected sample rate
double nam_get_expected_sample_rate(NamDSP* dsp);

// Input/Output level management
int32_t nam_has_input_level(NamDSP* dsp);
int32_t nam_has_output_level(NamDSP* dsp);
double nam_get_input_level(NamDSP* dsp);
double nam_get_output_level(NamDSP* dsp);
void nam_set_input_level(NamDSP* dsp, double level);
void nam_set_output_level(NamDSP* dsp, double level);

// Loudness management
int32_t nam_has_loudness(NamDSP* dsp);
double nam_get_loudness(NamDSP* dsp);
void nam_set_loudness(NamDSP* dsp, double loudness);

// Error handling
const char* nam_get_last_error(void);

#ifdef __cplusplus
}
#endif

#endif // NAM_FFI_WRAPPER_H
