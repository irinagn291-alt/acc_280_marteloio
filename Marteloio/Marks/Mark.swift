import Foundation

/// Role: Marks. Flat log of Fixes, Rhumbs, Luffs and Landfalls, each stamped with a daykey.
enum Mark: Equatable, Sendable, Identifiable {
    case fix(FixMark)
    case rhumb(RhumbMark)
    case luff(LuffMark)
    case landfall(Landfall)

    var id: UUID {
        switch self {
        case .fix(let mark): mark.id
        case .rhumb(let mark): mark.id
        case .luff(let mark): mark.id
        case .landfall(let mark): mark.id
        }
    }

    var daykey: Int {
        switch self {
        case .fix(let mark): mark.daykey
        case .rhumb(let mark): mark.daykey
        case .luff(let mark): mark.daykey
        case .landfall(let mark): mark.daykey
        }
    }
}

extension Mark: Codable {
    enum Kind: String, Codable {
        case fix
        case rhumb
        case luff
        case landfall
    }

    enum CodingKeys: String, CodingKey {
        case kind
        case fix
        case rhumb
        case luff
        case landfall
    }

    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        let kind = try container.decode(Kind.self, forKey: .kind)
        switch kind {
        case .fix:
            self = .fix(try container.decode(FixMark.self, forKey: .fix))
        case .rhumb:
            self = .rhumb(try container.decode(RhumbMark.self, forKey: .rhumb))
        case .luff:
            self = .luff(try container.decode(LuffMark.self, forKey: .luff))
        case .landfall:
            self = .landfall(try container.decode(Landfall.self, forKey: .landfall))
        }
    }

    func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        switch self {
        case .fix(let mark):
            try container.encode(Kind.fix, forKey: .kind)
            try container.encode(mark, forKey: .fix)
        case .rhumb(let mark):
            try container.encode(Kind.rhumb, forKey: .kind)
            try container.encode(mark, forKey: .rhumb)
        case .luff(let mark):
            try container.encode(Kind.luff, forKey: .kind)
            try container.encode(mark, forKey: .luff)
        case .landfall(let mark):
            try container.encode(Kind.landfall, forKey: .kind)
            try container.encode(mark, forKey: .landfall)
        }
    }
}
