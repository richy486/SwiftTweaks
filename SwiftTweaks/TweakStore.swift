//
//  TweakStore.swift
//  SwiftTweaks
//
//  Created by Bryan Clark on 11/5/15.
//  Copyright © 2015 Khan Academy. All rights reserved.
//

import Foundation

/// Looks up the persisted state for tweaks.
public class TweakStore {

	/// The "tree structure" for our Tweaks UI.
	private var tweakCollections: [String: TweakCollection] = [:]

	/// Caches "single" bindings - when a tweak is updated, we'll call each of the corresponding bindings.
	private var tweakBindings: [String: [AnyTweakBinding]] = [:]

	/// Caches "multi" bindings - when any tweak in a Set is updated, we'll call each of the corresponding bindings.
	private var tweakSetBindings: [Set<AnyTweak>: [() -> Void]] = [:]

	/// Persists tweaks' currentValues and maintains them on disk.
	private let persistence: TweakPersistency

	/// Creates a TweakStore, with information persisted on-disk. 
	/// If you want to have multiple TweakStores in your app, you can pass in a unique storeName to keep it separate from others on disk.
	public init(tweaks: [AnyTweak], storeName: String = "Tweaks") {
		self.persistence = TweakPersistency(identifier: storeName)

		tweaks.forEach { tweak in
			// Find or create its TweakCollection
			var tweakCollection: TweakCollection
			if let existingCollection = tweakCollections[tweak.collectionName] {
				tweakCollection = existingCollection
			} else {
				tweakCollection = TweakCollection(title: tweak.collectionName)
				tweakCollections[tweakCollection.title] = tweakCollection
			}

			// Find or create its TweakGroup
			var tweakGroup: TweakGroup
			if let existingGroup = tweakCollection.tweakGroups[tweak.groupName] {
				tweakGroup = existingGroup
			} else {
				tweakGroup = TweakGroup(title: tweak.groupName)
			}

			// Add the tweak to the tree
			tweakGroup.tweaks[tweak.tweakName] = tweak
			tweakCollection.tweakGroups[tweakGroup.title] = tweakGroup
			tweakCollections[tweakCollection.title] = tweakCollection
		}
	}

	/// Returns the current value for a given tweak
	public func assign<T>(tweak: Tweak<T>) -> T {
		return self.currentValueForTweak(tweak)
	}

	public func bind<T>(tweak: Tweak<T>, binding: (T) -> Void) {
		// Create the TweakBinding<T>, and wrap it in our type-erasing AnyTweakBinding
		let tweakBinding = TweakBinding(tweak: tweak, binding: binding)
		let anyTweakBinding = AnyTweakBinding(tweakBinding: tweakBinding)

		// Cache the binding
		let existingTweakBindings = tweakBindings[tweak.persistenceIdentifier] ?? []
		tweakBindings[tweak.persistenceIdentifier] = existingTweakBindings + [anyTweakBinding]

		// Then immediately apply the binding on whatever current value we have
		binding(currentValueForTweak(tweak))
	}

	public func bindMultiple(tweaks: [TweakType], binding: () -> Void) {
		// Convert the array (which makes it easier to call a `bindTweakSet`) into a set (which makes it possible to cache the tweakSet)
		let tweakSet = Set(tweaks.map(AnyTweak.init))

		// Cache the cluster binding
		let existingTweakSetBindings = tweakSetBindings[tweakSet] ?? []
		tweakSetBindings[tweakSet] = existingTweakSetBindings + [binding]

		// Immediately call the binding
		binding()
	}

	// MARK: - Internal
	
	/// Resets all tweaks to their `defaultValue`
	internal func reset() {
		persistence.clearAllData()

		// Go through all tweaks in our library, and call any bindings they're attached to.
		tweakCollections.values.reduce([]) { $0 + $1.sortedTweakGroups.reduce([]) { $0 + $1.sortedTweaks } }
			.forEach { updateBindingsForTweak($0)
		}

	}

	internal func currentValueForTweak<T>(tweak: Tweak<T>) -> T {
		// STOPSHIP (bryan): Return defaultValue in production, else return persistence.currentValue ?? defaultValue
		return shouldAllowTweaks ? persistence.currentValueForTweak(tweak) ?? tweak.defaultValue : tweak.defaultValue
	}

	internal func currentViewDataForTweak(tweak: AnyTweak) -> TweakViewData {
		let cachedValue = persistence.currentValueForTweakIdentifiable(tweak)

		switch tweak.tweakDefaultData {
		case let .Boolean(defaultValue: defaultValue):
			let currentValue = cachedValue as? Bool ?? defaultValue
			return .Boolean(value: currentValue, defaultValue: defaultValue)
		case let .Integer(defaultValue: defaultValue, min: min, max: max, stepSize: step):
			let currentValue = cachedValue as? Int ?? defaultValue
			return .Integer(value: currentValue, defaultValue: defaultValue, min: min, max: max, stepSize: step)
		case let .Float(defaultValue: defaultValue, min: min, max: max, stepSize: step):
			let currentValue = cachedValue as? CGFloat ?? defaultValue
			return .Float(value: currentValue, defaultValue: defaultValue, min: min, max: max, stepSize: step)
		case let .DoubleTweak(defaultValue: defaultValue, min: min, max: max, stepSize: step):
			let currentValue = cachedValue as? Double ?? defaultValue
			return .DoubleTweak(value: currentValue, defaultValue: defaultValue, min: min, max: max, stepSize: step)
		case let .Color(defaultValue: defaultValue):
			let currentValue = cachedValue as? UIColor ?? defaultValue
			return .Color(value: currentValue, defaultValue: defaultValue)
		}
	}

	internal func setValue(viewData: TweakViewData, forTweak tweak: AnyTweak) {
		persistence.setValue(viewData.value, forTweakIdentifiable: tweak)
		updateBindingsForTweak(tweak)
	}

	// MARK - Private

	private var shouldAllowTweaks: Bool {
		return true // STOPSHIP (bryan): figure out whether we're in production or debug.
	}

	private func updateBindingsForTweak(tweak: AnyTweak) {
		// Find any 1-to-1 bindings and update them
		tweakBindings[tweak.persistenceIdentifier]?.forEach {
			$0.applyBindingWithValue(currentViewDataForTweak(tweak).value)
		}

		// Find any cluster bindings and update them
		for (tweakSet, bindingsArray) in tweakSetBindings {
			if tweakSet.contains(tweak) {
				bindingsArray.forEach { $0() }
			}
		}
	}
}

extension TweakStore {
	internal var sortedTweakCollections: [TweakCollection] {
		return tweakCollections
			.sort { $0.0 < $1.0 }
			.map { return $0.1 }
	}
}