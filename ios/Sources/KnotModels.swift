import Foundation

struct CrossingOrderEntry: Codable, Equatable {
    let cid: Int
    let label: String
    let xNorm: Double
    let yNorm: Double
    
    enum CodingKeys: String, CodingKey {
        case cid
        case label
        case xNorm = "x_norm"
        case yNorm = "y_norm"
    }
}

struct KnotResponse: Codable, Identifiable, Equatable {
    let id: String
    let rawImageUrl: String?
    let detectionUrl: String?
    let traversalUrl: String?
    let visualizationUrl: String?
    let mode: String?
    let sequence: [String]?
    let crossingsOrder: [CrossingOrderEntry]?
    let knotNotation: KnotNotation?
    let pdCode: PDCode?
    let topology: Topology?
    let timing: [String: Double]?
    
    enum CodingKeys: String, CodingKey {
        case id
        case rawImageUrl = "raw_image_url"
        case detectionUrl = "detection_url"
        case traversalUrl = "traversal_url"
        case visualizationUrl = "visualization_url"
        case mode
        case sequence
        case crossingsOrder = "crossings_order"
        case knotNotation = "knot_notation"
        case pdCode = "pd_code"
        case topology
        case timing
    }
    
    static func == (lhs: KnotResponse, rhs: KnotResponse) -> Bool {
        return lhs.id == rhs.id
    }
}

struct KnotNotation: Codable, Equatable {
    let compact: String?
    let full: String?
}

struct PDCode: Codable, Equatable {
    let pdCodeStr: String?
    let writhe: Int?
    
    enum CodingKeys: String, CodingKey {
        case pdCodeStr = "pd_code_str"
        case writhe
    }
}

struct Topology: Codable, Equatable {
    let gaussCode: String?
    let dtNotation: String?
    let writhe: Int?
    let nCrossings: Int?
    let jonesStr: String?
    
    enum CodingKeys: String, CodingKey {
        case gaussCode = "gauss_code"
        case dtNotation = "dt_notation"
        case writhe
        case nCrossings = "n_crossings"
        case jonesStr = "jones_str"
    }
}

