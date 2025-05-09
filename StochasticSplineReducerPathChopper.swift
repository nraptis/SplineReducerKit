//
//  StochasticSplineReducerPathChopper.swift
//  PoopMeasure
//
//  Created by Nick Raptis on 12/3/24.
//

import Foundation

class StochasticSplineReducerPathChopper {

    static let maxMaximumStep = 20
    static let minMinimumStep = 2
    
    var trenchCount = 0
    let trenches: [StochasticSplineReducerPathTrench]
    init() {
        var _trenches = [StochasticSplineReducerPathTrench]()
        _trenches.reserveCapacity(Self.maxMaximumStep)
        for index in 0..<Self.maxMaximumStep {
            _trenches.append(StochasticSplineReducerPathTrench(startIndex: index))
        }
        trenches = _trenches
    }
    
    func reset() {
        for index in 0..<Self.maxMaximumStep {
            trenches[index].reset()
        }
        
    }
    
    // the assumption here is that
    // our path loops back to the start.
    func build(pathLength: Int,
               minimumStep: Int,
               maximumStep: Int) -> Bool {
        
        if pathLength < minimumStep {
            trenchCount = 0
            return false
        }
        if minimumStep < StochasticSplineReducerPathChopper.minMinimumStep {
            return false
        }
        if maximumStep > StochasticSplineReducerPathChopper.maxMaximumStep {
            return false
        }
        if maximumStep < minimumStep {
            return false
        }
        
        // We can start anywhere from 0...(maximumStep - 1)
        for startIndex in 0..<maximumStep {
            if startIndex < pathLength {
                trenches[startIndex].reset()
                if !trenches[startIndex].build(pathLength: pathLength,
                                               minimumStep: minimumStep,
                                               maximumStep: maximumStep) {
                    trenchCount = 0
                    return false
                }
            }
        }
        trenchCount = min(maximumStep, pathLength)
        return true
    }
    
    var path = [Int]()
    var pathCount = 0
    
    func pathAdd(number: Int) {
        while path.count <= pathCount {
            path.append(number)
        }
        path[pathCount] = number
        pathCount += 1
    }
    
    func solve() {
        pathCount = 0
        if trenchCount > 0 {
            let trenchIndex = Int.random(in: 0..<trenchCount)
            let trench = trenches[trenchIndex]
            var node = trench.nodes[trench.startIndex]
            if node.linkCount <= 0 { return }
            var linkIndex = Int.random(in: 0..<node.linkCount)
            var link = node.links[linkIndex]
            pathAdd(number: trench.startIndex)
            while link != trench.startIndex {
                node = trench.nodes[link]
                if node.linkCount <= 0 { return }
                pathAdd(number: link)
                linkIndex = Int.random(in: 0..<node.linkCount)
                link = node.links[linkIndex]
            }
        }
    }
}
