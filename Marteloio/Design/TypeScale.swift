import SwiftUI
import UIKit

/// Role: Design. Six steps. Island names are Title3 semibold. Arithmetic uses tabular digits.
enum TypeScale {
    static var display: Font {
        .system(.largeTitle, design: .serif).weight(.regular)
    }

    static var title: Font {
        .title3.weight(.semibold)
    }

    static var body: Font {
        .system(size: 17, weight: .regular)
    }

    static var caption: Font {
        .caption
    }

    static var tabular: Font {
        .body.monospacedDigit().weight(.semibold)
    }

    static var bearing: Font {
        .caption2.width(.expanded).weight(.semibold)
    }

    static func uiTitle3() -> UIFont {
        let base = UIFont.preferredFont(forTextStyle: .title3)
        let font = UIFont.systemFont(ofSize: base.pointSize, weight: .semibold)
        return UIFontMetrics(forTextStyle: .title3).scaledFont(for: font)
    }

    static func uiTabular(_ style: UIFont.TextStyle) -> UIFont {
        let base = UIFont.preferredFont(forTextStyle: style)
        let mono = UIFont.monospacedDigitSystemFont(ofSize: base.pointSize, weight: .semibold)
        return UIFontMetrics(forTextStyle: style).scaledFont(for: mono)
    }

    static func uiRunNumeral() -> UIFont {
        let base = UIFont.preferredFont(forTextStyle: .title1)
        let mono = UIFont.monospacedDigitSystemFont(ofSize: base.pointSize, weight: .bold)
        return UIFontMetrics(forTextStyle: .title1).scaledFont(for: mono)
    }

    static func uiCaption() -> UIFont {
        UIFont.preferredFont(forTextStyle: .caption2)
    }

    static func uiBearing() -> UIFont {
        let base = UIFont.preferredFont(forTextStyle: .caption2)
        let descriptor = base.fontDescriptor.addingAttributes([
            UIFontDescriptor.AttributeName.featureSettings: [
                [
                    UIFontDescriptor.FeatureKey.type: kUpperCaseType,
                    UIFontDescriptor.FeatureKey.selector: kUpperCaseSmallCapsSelector,
                ],
                [
                    UIFontDescriptor.FeatureKey.type: kNumberSpacingType,
                    UIFontDescriptor.FeatureKey.selector: kMonospacedNumbersSelector,
                ],
            ],
        ])
        let font = UIFont(descriptor: descriptor, size: base.pointSize)
        return UIFontMetrics(forTextStyle: .caption2).scaledFont(for: font)
    }

    static func uiBody() -> UIFont {
        UIFont.preferredFont(forTextStyle: .body)
    }
}
