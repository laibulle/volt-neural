#include "nam.h"
#include <exception>
#include <string>
#include <iostream>

// We'll attempt to include NAM headers if available
// For now, this is a stub that will be filled in once NAM is available
// #include "NAM/get_dsp.h"
// #include "NAM/dsp.h"

static thread_local std::string g_last_error;

// Forward declaration of NAM functions (will be linked)
// namespace nam {
//   std::unique_ptr<DSP> get_dsp(const std::filesystem::path config_filename);
//   struct DSP { /* methods */ };
// }

extern "C" {

NamDSP* nam_load_model(const char* model_path) {
    if (model_path == nullptr) {
        g_last_error = "Model path is null";
        return nullptr;
    }

    try {
        // TODO: Uncomment when NAM library is available
        // auto dsp = nam::get_dsp(model_path);
        // if (dsp) {
        //     NamDSP* result = new NamDSP();
        //     result->ptr = dsp.release();
        //     return result;
        // }
        // g_last_error = "Failed to load NAM model";
        // return nullptr;

        g_last_error = "NAM library not yet integrated";
        return nullptr;
    } catch (const std::exception& e) {
        g_last_error = std::string("Exception loading model: ") + e.what();
        return nullptr;
    }
}

void nam_free_model(NamDSP* dsp) {
    if (dsp && dsp->ptr) {
        // TODO: Uncomment when NAM library is available
        // auto* nam_dsp = static_cast<nam::DSP*>(dsp->ptr);
        // delete nam_dsp;
        // delete dsp;
    }
}

void nam_process(NamDSP* dsp, const NAM_SAMPLE* input, NAM_SAMPLE* output, int32_t num_frames) {
    if (dsp == nullptr || dsp->ptr == nullptr) {
        return;
    }

    try {
        // TODO: Uncomment when NAM library is available
        // auto* nam_dsp = static_cast<nam::DSP*>(dsp->ptr);
        // nam_dsp->process((float*)input, (float*)output, (int)num_frames);
    } catch (const std::exception& e) {
        g_last_error = std::string("Exception in process: ") + e.what();
    }
}

void nam_reset(NamDSP* dsp, double sample_rate, int32_t max_buffer_size) {
    if (dsp == nullptr || dsp->ptr == nullptr) {
        return;
    }

    try {
        // TODO: Uncomment when NAM library is available
        // auto* nam_dsp = static_cast<nam::DSP*>(dsp->ptr);
        // nam_dsp->Reset(sample_rate, (int)max_buffer_size);
    } catch (const std::exception& e) {
        g_last_error = std::string("Exception in reset: ") + e.what();
    }
}

void nam_prewarm(NamDSP* dsp) {
    if (dsp == nullptr || dsp->ptr == nullptr) {
        return;
    }

    try {
        // TODO: Uncomment when NAM library is available
        // auto* nam_dsp = static_cast<nam::DSP*>(dsp->ptr);
        // nam_dsp->prewarm();
    } catch (const std::exception& e) {
        g_last_error = std::string("Exception in prewarm: ") + e.what();
    }
}

double nam_get_expected_sample_rate(NamDSP* dsp) {
    if (dsp == nullptr || dsp->ptr == nullptr) {
        return -1.0;
    }

    try {
        // TODO: Uncomment when NAM library is available
        // auto* nam_dsp = static_cast<nam::DSP*>(dsp->ptr);
        // return nam_dsp->GetExpectedSampleRate();
        return -1.0;
    } catch (const std::exception& e) {
        g_last_error = std::string("Exception in get_expected_sample_rate: ") + e.what();
        return -1.0;
    }
}

int32_t nam_has_input_level(NamDSP* dsp) {
    if (dsp == nullptr || dsp->ptr == nullptr) {
        return 0;
    }

    try {
        // TODO: Uncomment when NAM library is available
        // auto* nam_dsp = static_cast<nam::DSP*>(dsp->ptr);
        // return nam_dsp->HasInputLevel() ? 1 : 0;
        return 0;
    } catch (const std::exception& e) {
        g_last_error = std::string("Exception in has_input_level: ") + e.what();
        return 0;
    }
}

int32_t nam_has_output_level(NamDSP* dsp) {
    if (dsp == nullptr || dsp->ptr == nullptr) {
        return 0;
    }

    try {
        // TODO: Uncomment when NAM library is available
        // auto* nam_dsp = static_cast<nam::DSP*>(dsp->ptr);
        // return nam_dsp->HasOutputLevel() ? 1 : 0;
        return 0;
    } catch (const std::exception& e) {
        g_last_error = std::string("Exception in has_output_level: ") + e.what();
        return 0;
    }
}

double nam_get_input_level(NamDSP* dsp) {
    if (dsp == nullptr || dsp->ptr == nullptr) {
        return 0.0;
    }

    try {
        // TODO: Uncomment when NAM library is available
        // auto* nam_dsp = static_cast<nam::DSP*>(dsp->ptr);
        // return nam_dsp->GetInputLevel();
        return 0.0;
    } catch (const std::exception& e) {
        g_last_error = std::string("Exception in get_input_level: ") + e.what();
        return 0.0;
    }
}

double nam_get_output_level(NamDSP* dsp) {
    if (dsp == nullptr || dsp->ptr == nullptr) {
        return 0.0;
    }

    try {
        // TODO: Uncomment when NAM library is available
        // auto* nam_dsp = static_cast<nam::DSP*>(dsp->ptr);
        // return nam_dsp->GetOutputLevel();
        return 0.0;
    } catch (const std::exception& e) {
        g_last_error = std::string("Exception in get_output_level: ") + e.what();
        return 0.0;
    }
}

void nam_set_input_level(NamDSP* dsp, double level) {
    if (dsp == nullptr || dsp->ptr == nullptr) {
        return;
    }

    try {
        // TODO: Uncomment when NAM library is available
        // auto* nam_dsp = static_cast<nam::DSP*>(dsp->ptr);
        // nam_dsp->SetInputLevel(level);
    } catch (const std::exception& e) {
        g_last_error = std::string("Exception in set_input_level: ") + e.what();
    }
}

void nam_set_output_level(NamDSP* dsp, double level) {
    if (dsp == nullptr || dsp->ptr == nullptr) {
        return;
    }

    try {
        // TODO: Uncomment when NAM library is available
        // auto* nam_dsp = static_cast<nam::DSP*>(dsp->ptr);
        // nam_dsp->SetOutputLevel(level);
    } catch (const std::exception& e) {
        g_last_error = std::string("Exception in set_output_level: ") + e.what();
    }
}

int32_t nam_has_loudness(NamDSP* dsp) {
    if (dsp == nullptr || dsp->ptr == nullptr) {
        return 0;
    }

    try {
        // TODO: Uncomment when NAM library is available
        // auto* nam_dsp = static_cast<nam::DSP*>(dsp->ptr);
        // return nam_dsp->HasLoudness() ? 1 : 0;
        return 0;
    } catch (const std::exception& e) {
        g_last_error = std::string("Exception in has_loudness: ") + e.what();
        return 0;
    }
}

double nam_get_loudness(NamDSP* dsp) {
    if (dsp == nullptr || dsp->ptr == nullptr) {
        return 0.0;
    }

    try {
        // TODO: Uncomment when NAM library is available
        // auto* nam_dsp = static_cast<nam::DSP*>(dsp->ptr);
        // return nam_dsp->GetLoudness();
        return 0.0;
    } catch (const std::exception& e) {
        g_last_error = std::string("Exception in get_loudness: ") + e.what();
        return 0.0;
    }
}

void nam_set_loudness(NamDSP* dsp, double loudness) {
    if (dsp == nullptr || dsp->ptr == nullptr) {
        return;
    }

    try {
        // TODO: Uncomment when NAM library is available
        // auto* nam_dsp = static_cast<nam::DSP*>(dsp->ptr);
        // nam_dsp->SetLoudness(loudness);
    } catch (const std::exception& e) {
        g_last_error = std::string("Exception in set_loudness: ") + e.what();
    }
}

const char* nam_get_last_error(void) {
    return g_last_error.c_str();
}

} // extern "C"
