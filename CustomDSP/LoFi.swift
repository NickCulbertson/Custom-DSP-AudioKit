import AudioKit
import AudioKitEX
import AVFoundation
import CAudioKitEX

/// LoFi Effect
public class LoFi: Node {
    let input: Node

    /// Connected nodes
    public var connections: [Node] { [input] }

    /// Underlying AVAudioNode
    public var avAudioNode = instantiate(effect: "lofs")

    // MARK: - Parameters

    /// Specification details for gain
    public static let gainDef = NodeParameterDef(
        identifier: "gain",
        name: "Gain",
        address: akGetParameterAddress("LoFiParameterGain"),
        defaultValue: 0,
        range: -25 ... 25,
        unit: .generic
    )

    @Parameter(gainDef) public var gain: AUValue

    // MARK: - Initialization

    /// Initialize this LoFi node
    ///
    /// - Parameters:
    ///   - input: Input node to process
    ///   - gain: -25 to 25 db gain control
    ///
    public init(
        _ input: Node,
        gain: AUValue = gainDef.defaultValue
    ) {
        self.input = input
        setupParameters()
        self.gain = gain
    }
}
