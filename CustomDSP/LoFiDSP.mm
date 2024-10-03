#include "SoundpipeDSPBase.h"
#include "ParameterRamper.h"
#include "Soundpipe.h"
#include <vector>

enum LoFiParameter : AUParameterAddress {
    LoFiParameterGain,
};

class LoFiDSP : public SoundpipeDSPBase {
private:
    ParameterRamper gainRamp;
    sp_butlp *lowpass;        // Low-pass filter
    sp_vdelay *vdelay;        // Variable delay for pitch wobble
    sp_osc *lfo;              // LFO for modulation
    sp_ftbl *lfoTable;        // Wavetable for the LFO
    std::vector<float> wavetable;

public:
    LoFiDSP() {
        // Register the gain parameter with the internal ramper
        parameters[LoFiParameterGain] = &gainRamp;
    }

    void init(int channelCount, double sampleRate) override {
        SoundpipeDSPBase::init(channelCount, sampleRate);
        gainRamp.init();
        gainRamp.setUIValue(0.0f); // Default gain value (0 dB, unchanged)

        // Initialize low-pass filter
        sp_butlp_create(&lowpass);
        sp_butlp_init(sp, lowpass);
        lowpass->freq = 800.0f;       // Set initial cutoff frequency to 1.5kHz for lo-fi effect

        // Initialize variable delay for pitch wobble
        sp_vdelay_create(&vdelay);
        sp_vdelay_init(sp, vdelay, 1.0); // Max delay time of 1 second
        vdelay->del = 0.01f;            // Set initial delay to 10ms (for subtle pitch effect)

        // Initialize LFO for modulation
        wavetable = std::vector<float>(2048, 0.0f);
        sp_ftbl_create(sp, &lfoTable, wavetable.size());
        sp_gen_sine(sp, lfoTable); // Generate a sine wave for the LFO

        sp_osc_create(&lfo);
        sp_osc_init(sp, lfo, lfoTable, 0);
        lfo->freq = 0.25f;              // LFO frequency of 0.25 Hz (slow wobble)
        lfo->amp = 0.015f;              // Small amplitude for subtle modulation of delay time
    }

    void deinit() override {
        SoundpipeDSPBase::deinit();

        // Destroy effects
        sp_butlp_destroy(&lowpass);
        sp_vdelay_destroy(&vdelay);
        sp_osc_destroy(&lfo);
        sp_ftbl_destroy(&lfoTable);
    }

    void reset() override {
        SoundpipeDSPBase::reset();
    }

    void process(FrameRange range) override {
        // Iterate over the range of frames to process the input with the gain value
        for (int i : range) {
            float gainDb = gainRamp.getAndStep(); // Get current gain value in dB
            float gainLinear = powf(10.0f, gainDb / 20.0f); // Convert dB to linear gain

            // Generate the LFO signal for pitch modulation
            float lfoValue;
            float dummyInput = 0.0f;
            sp_osc_compute(sp, lfo, &dummyInput, &lfoValue); // Use dummyInput as required input

            // Adjust the delay time to create the wobble effect
            vdelay->del = 1.1f + lfoValue; // Base delay of 10ms modulated by LFO for subtle wobble

            // For each channel, apply gain, filtering, and pitch wobble
            for (int channel = 0; channel < channelCount; ++channel) {
                float input = inputSample(channel, i);
                float &output = outputSample(channel, i);

                // Step 1: Apply gain
                float processedSample = input * gainLinear;

                // Step 2: Apply low-pass filter for lo-fi effect
                float filteredSample;
                sp_butlp_compute(sp, lowpass, &processedSample, &filteredSample);

                // Step 3: Apply variable delay for pitch wobble effect
                float pitchWobbledSample;
                sp_vdelay_compute(sp, vdelay, &filteredSample, &pitchWobbledSample);

                // Step 4: Set the output (no blending needed, as the pitch-wobbled signal is the final result)
                output = pitchWobbledSample;
            }
        }
    }
};

// Register the DSP and its parameter so AudioKit can find it
AK_REGISTER_DSP(LoFiDSP, "lofs")
AK_REGISTER_PARAMETER(LoFiParameterGain)
