#include "SoundpipeDSPBase.h"
#include "ParameterRamper.h"
#include "Soundpipe.h"
#include <cmath>

enum BoosterParameter : AUParameterAddress {
    BoosterParameterGain,
};

class BoosterDSP : public SoundpipeDSPBase {
private:
    ParameterRamper gainRamp;
    
public:
    BoosterDSP() {
        parameters[BoosterParameterGain] = &gainRamp;
    }
    
    void init(int channelCount, double sampleRate) override {
        SoundpipeDSPBase::init(channelCount, sampleRate);
    }
    
    void deinit() override {
        SoundpipeDSPBase::deinit();
    }
    
    void reset() override {
        SoundpipeDSPBase::reset();
    }
    
    void process(FrameRange range) override {
        for (int i : range) {
            float gainDb = gainRamp.getAndStep();
            float gain = powf(10.0f, gainDb / 20.0f); // Convert dB to linear gain
            
            for (int channel = 0; channel < 2; ++channel) {
                float in = inputSample(channel, i);
                float &out = outputSample(channel, i);
                out = in * gain;
            }
        }
    }
};

AK_REGISTER_DSP(BoosterDSP, "boos")
AK_REGISTER_PARAMETER(BoosterParameterGain)
