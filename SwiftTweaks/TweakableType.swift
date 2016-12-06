//
//  TweakableType.swift
//  SwiftTweaks
//
//  Created by Bryan Clark on 11/5/15.
//  Copyright © 2015 Khan Academy. All rights reserved.
//

import Foundation
import CoreGraphics
import UIKit

/// To add a new <T> to our Tweak<T>, make T conform to this protocol.
public protocol TweakableType {
	static var tweakViewDataType: TweakViewDataType { get }
}

/// The data types that are currently supported for SwiftTweaks.
/// While Tweak<T> is generic, we have to build UI for editing each kind of <T> - hence the need for a protocol to restrict what can be tweaked.
/// Of course, we can add new TweakViewDataTypes over time, too!
public enum TweakViewDataType {
	case boolean
	case integer
	case cgFloat
	case double
	case uiColor
	case stringList

	public static let allTypes: [TweakViewDataType] = [
		.boolean, .integer, .cgFloat, .double, .uiColor, .stringList
	]
}

/// An enum for use inside Tweaks' editing UI.
/// Our public type-erasure (AnyTweak) means that this has to be public, unfortunately
/// ...but there's no need for you to directly use this enum.
public enum TweakDefaultData {
	case boolean(defaultValue: Bool)
	case integer(defaultValue: Int, min: Int?, max: Int?, stepSize: Int?)
	case float(defaultValue: CGFloat, min: CGFloat?, max: CGFloat?, stepSize: CGFloat?)
	case doubleTweak(defaultValue: Double, min: Double?, max: Double?, stepSize: Double?)
	case color(defaultValue: UIColor)
	case stringList(defaultValue: StringOption, options: [StringOption])
}

// MARK: Types that conform to TweakableType

public struct StringOption {
	public let value: String
	init(value: String) {
		self.value = value
	}
}

extension StringOption: TweakableType {
	public static var tweakViewDataType: TweakViewDataType {
		return .stringList
	}
}

extension StringOption: Equatable {
	public static func ==(lhs: StringOption, rhs: StringOption) -> Bool {
		return lhs.value == rhs.value
	}

}

extension Bool: TweakableType {
	public static var tweakViewDataType: TweakViewDataType {
		return .boolean
	}
}

extension Int: TweakableType {
	public static var tweakViewDataType: TweakViewDataType {
		return .integer
	}
}

extension CGFloat: TweakableType {
	public static var tweakViewDataType: TweakViewDataType {
		return .cgFloat
	}
}

extension Double: TweakableType {
	public static var tweakViewDataType: TweakViewDataType {
		return .double
	}
}

extension UIColor: TweakableType {
	public static var tweakViewDataType: TweakViewDataType {
		return .uiColor
	}
}

