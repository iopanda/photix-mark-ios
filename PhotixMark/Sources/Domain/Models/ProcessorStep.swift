import Foundation

public indirect enum StepValue: Codable, Sendable {
    case string(String)
    case double(Double)
    case bool(Bool)
    case array([StepValue])
    case dict([String: StepValue])

    private enum CodingKeys: String, CodingKey { case type, value }

    public init(from decoder: Decoder) throws {
        let c = try decoder.container(keyedBy: CodingKeys.self)
        let type = try c.decode(String.self, forKey: .type)
        switch type {
        case "string": self = .string(try c.decode(String.self, forKey: .value))
        case "double": self = .double(try c.decode(Double.self, forKey: .value))
        case "bool":   self = .bool(try c.decode(Bool.self, forKey: .value))
        case "array":  self = .array(try c.decode([StepValue].self, forKey: .value))
        case "dict":   self = .dict(try c.decode([String: StepValue].self, forKey: .value))
        default: throw DecodingError.dataCorruptedError(forKey: .type, in: c, debugDescription: "Unknown StepValue type")
        }
    }

    public func encode(to encoder: Encoder) throws {
        var c = encoder.container(keyedBy: CodingKeys.self)
        switch self {
        case .string(let v): try c.encode("string", forKey: .type); try c.encode(v, forKey: .value)
        case .double(let v): try c.encode("double", forKey: .type); try c.encode(v, forKey: .value)
        case .bool(let v):   try c.encode("bool",   forKey: .type); try c.encode(v, forKey: .value)
        case .array(let v):  try c.encode("array",  forKey: .type); try c.encode(v, forKey: .value)
        case .dict(let v):   try c.encode("dict",   forKey: .type); try c.encode(v, forKey: .value)
        }
    }

    public var stringValue: String? { if case .string(let v) = self { return v }; return nil }
    public var doubleValue: Double? { if case .double(let v) = self { return v }; return nil }
    public var boolValue: Bool?     { if case .bool(let v)   = self { return v }; return nil }
    public var arrayValue: [StepValue]? { if case .array(let v) = self { return v }; return nil }
    public var dictValue: [String: StepValue]? { if case .dict(let v) = self { return v }; return nil }
}

public struct ProcessorStep: Codable, Sendable {
    public var processorName: String
    public var stepConfig: [String: StepValue]

    public init(processorName: String, stepConfig: [String: StepValue] = [:]) {
        self.processorName = processorName
        self.stepConfig = stepConfig
    }
}
