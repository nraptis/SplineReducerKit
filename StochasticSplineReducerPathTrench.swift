//
//  StochasticSplineReducerPathTrench.swift
//  PoopMeasure
//
//  Created by Nick Raptis on 12/3/24.
//

import Foundation

class StochasticSplineReducerPathTrench {
    
    let startIndex: Int
    init(startIndex: Int) {
        self.startIndex = startIndex
    }
    
    var nodes = [StochasticSplineReducerPathChopperNode]()
    var nodeCount = 0
    
    var dynamicReachable = [Bool]()
    var dynamicReachableCount = 0
    func calculateDynamic(pathLength: Int,
                          minimumStep: Int,
                          maximumStep: Int) {
        if pathLength < minimumStep {
            return
        }
        if minimumStep < StochasticSplineReducerPathChopper.minMinimumStep {
            return
        }
        dynamicReachableCount = (pathLength + 1)
        while dynamicReachable.count < dynamicReachableCount {
            dynamicReachable.append(false)
        }
        for index in 0..<dynamicReachableCount {
            dynamicReachable[index] = false
        }
        dynamicReachable[0] = true
        for pathIndex in 1..<dynamicReachableCount {
            for step in minimumStep...maximumStep {
                if pathIndex >= step {
                    if dynamicReachable[pathIndex - step] == true {
                        dynamicReachable[pathIndex] = true
                        break
                    }
                }
            }
        }
    }
    
    func getNumberOfStepsPossible(exactDistance: Int,
                                  minimumStep: Int,
                                  maximumStep: Int) -> Bool {
        if minimumStep < StochasticSplineReducerPathChopper.minMinimumStep {
            return false
        }
        
        if exactDistance <= 0 {
            return true
        }
        
        if exactDistance >= dynamicReachableCount {
            return false
        }
        return dynamicReachable[exactDistance]
    }
    
    func reset() {
        for nodeIndex in 0..<nodeCount {
            nodes[nodeIndex].reset()
        }
        nodeCount = 0
    }
    
    func wrapIndex(index: Int,
                   pathLength: Int) -> Int {
        var result = index
        if result < 0 { result += pathLength }
        if result >= pathLength { result -= pathLength }
        return result
    }
    
    func getDistanceToStartIndexMovingForward(index: Int,
                                              pathLength: Int) -> Int {
        if index < 0 {
            return 0
        }
        if index >= pathLength {
            return 0
        }
        if index <= startIndex {
            return startIndex - index
        } else {
            return pathLength - index + startIndex
        }
    }
    
    // @Precon: calculateDynamic
    func isPossibleToPlaceNode(index: Int,
                               pathLength: Int,
                               minimumStep: Int,
                               maximumStep: Int) -> Bool {
        
        if pathLength < minimumStep {
            return false
        }
        if minimumStep < StochasticSplineReducerPathChopper.minMinimumStep {
            return false
        }
        if index < 0 {
            return false
        }
        if index >= pathLength {
            return false
        }
        
        let distanceToEnd = getDistanceToStartIndexMovingForward(index: index,
                                                                 pathLength: pathLength)
        
        return getNumberOfStepsPossible(exactDistance: distanceToEnd,
                                        minimumStep: minimumStep,
                                        maximumStep: maximumStep)
    }
    
    func build(pathLength: Int,
               minimumStep: Int,
               maximumStep: Int) -> Bool {
        
        while nodes.count < pathLength {
            nodes.append(StochasticSplineReducerPathChopperNode())
        }
        nodeCount = pathLength
        for nodeIndex in 0..<nodeCount {
            nodes[nodeIndex].reset()
        }
        
        // Ok, is this possible?
        if startIndex < 0 { return false }
        if startIndex >= nodeCount { return false }
        if pathLength < minimumStep { return false }
        
        calculateDynamic(pathLength: pathLength,
                         minimumStep: minimumStep,
                         maximumStep: maximumStep)
        
        if getNumberOfStepsPossible(exactDistance: pathLength,
                                    minimumStep: minimumStep,
                                    maximumStep: maximumStep) == false {
            return false
        }
        
        var isAnyLinkFound = false
        for step in minimumStep...maximumStep {
            if step < pathLength {
                let wrappedIndex = wrapIndex(index: startIndex + step,
                                             pathLength: pathLength)
                if isPossibleToPlaceNode(index: wrappedIndex,
                                         pathLength: pathLength,
                                         minimumStep: minimumStep,
                                         maximumStep: maximumStep) {
                    isAnyLinkFound = true
                    nodes[startIndex].addLink(wrappedIndex)
                    build(index: wrappedIndex,
                          pathLength: pathLength,
                          minimumStep: minimumStep,
                          maximumStep: maximumStep)
                }
            }
        }
        return isAnyLinkFound
    }
    
    private func build(index: Int,
                       pathLength: Int,
                       minimumStep: Int,
                       maximumStep: Int) {
        
        if nodes[index].linkCount > 0 {
            return
        }
        
        for step in minimumStep...maximumStep {
            if step < pathLength {
                let distanceToStartIndex = getDistanceToStartIndexMovingForward(index: index,
                                                                                pathLength: pathLength)
                if distanceToStartIndex >= step {
                    let wrappedIndex = wrapIndex(index: index + step,
                                                 pathLength: pathLength)
                    if isPossibleToPlaceNode(index: wrappedIndex,
                                             pathLength: pathLength,
                                             minimumStep: minimumStep,
                                             maximumStep: maximumStep) {
                        nodes[index].addLink(wrappedIndex)
                        build(index: wrappedIndex,
                              pathLength: pathLength,
                              minimumStep: minimumStep,
                              maximumStep: maximumStep)
                    }
                }
            }
        }
    }
}
