//
//  StochasticSplineReducerCommand.swift
//  Yo Mamma Be Ugly
//
//  Created by Nick Raptis on 12/3/24.
//

import Foundation

public enum StochasticSplineReducerCommand {
    case reduceFrontAndBack(StochasticSplineReducerNeighborCommandData)
    case reduceBackOnly(StochasticSplineReducerNeighborCommandData)
    case chopper(StochasticSplineReducerChopperCommandData)
}

public struct StochasticSplineReducerChopperCommandData {
    let tolerance: Float
    let minimumStep: Int
    let maximumStep: Int
    let tryCount: Int
    let dupeOrInvalidRetryCount: Int
    public init(tolerance: Float, minimumStep: Int, maximumStep: Int, tryCount: Int, dupeOrInvalidRetryCount: Int) {
        self.tolerance = tolerance
        self.minimumStep = minimumStep
        self.maximumStep = maximumStep
        self.tryCount = tryCount
        self.dupeOrInvalidRetryCount = dupeOrInvalidRetryCount
    }
}

public struct StochasticSplineReducerNeighborCommandData {
    let tolerance: Float
    let tryCount: Int
    let maxCombinedPouches: Int
    public init(tolerance: Float, tryCount: Int, maxCombinedPouches: Int) {
        self.tolerance = tolerance
        self.tryCount = tryCount
        self.maxCombinedPouches = maxCombinedPouches
    }
}
