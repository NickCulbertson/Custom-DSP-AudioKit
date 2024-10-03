import SwiftUI
import AudioKit
import SoundpipeAudioKit

class ContentViewConductor : ObservableObject {
    let engine = AudioEngine()
    var player = AudioPlayer()
    var effect: Booster
    @Published var isPlaying = false
    @Published var bypassEffect = false
    @Published var gainValue: Float = 0 {
        didSet {
            effect.gain = AUValue(gainValue)
        }
    }

    init() {
        effect = Booster(player)
        engine.output = effect
        loadAudio()
        try? engine.start()
    }
    
    func loadAudio() {
        do {
            if let fileURL = Bundle.main.url(forResource: "Piano", withExtension: "mp3") {
                try player.load(url: fileURL)
            } else {
                Log("Could not find file")
            }
        } catch {
            Log("Could not load player")
        }
    }
    
    func togglePlaying() {
        isPlaying.toggle()
        if isPlaying {
            player.play()
        } else {
            player.stop()
        }
    }
    
    func toggleEffect() {
        bypassEffect.toggle()
        if bypassEffect {
            effect.stop()
        } else {
            effect.start()
        }
    }
}

struct ContentView: View {
    @StateObject var conductor = ContentViewConductor()
    var body: some View {
        VStack {
            Button(action: {
                conductor.togglePlaying()
            }, label: {
                Image(systemName: conductor.isPlaying ? "stop.fill" : "play.fill")
            }).padding()
            
            Button(action: {
                conductor.toggleEffect()
            }, label: {
                Text(conductor.bypassEffect ? "Effect: Bypassed" : "Effect: Enabled")
                
            }).padding()
            
            Slider(value: $conductor.gainValue, in: -25...25, step: 1) {
                Text("Gain")
            }
            .padding()
            
            Text("Gain: \(Int(conductor.gainValue)) dB")
                .padding(.top, 10)
        }
        .padding()
    }
}

#Preview {
    ContentView()
}
