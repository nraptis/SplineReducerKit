//
//  StochasticSplineReducerBucket.swift
//  Yo Mamma Be Ugly
//
//  Created by Nick Raptis on 11/30/24.
//

import Foundation

class StochasticSplineReducerBucket {
    
    var isVisited = false
    
    var segments = [StochasticSplineReducerSegment]()
    var segmentCount = 0
    
    var x = Float(0.0)
    var y = Float(0.0)
    
    var originalIndex = -1
    
    var numberOfCombinedbuckets = 1
    
    // [S.R. Czech] 12-3-2024: This function works as intended.
    func addSegment(_ segment: StochasticSplineReducerSegment) {
        while segments.count <= segmentCount {
            segments.append(segment)
        }
        segments[segmentCount] = segment
        segmentCount += 1
    }
    
    // [S.R. Czech] 12-3-2024: This function works as intended.
    static func transferAllSegments(from fromPouch: StochasticSplineReducerBucket,
                                    to toPouch: StochasticSplineReducerBucket) {
        for segmentIndex in 0..<fromPouch.segmentCount {
            let segment = fromPouch.segments[segmentIndex]
            toPouch.addSegment(segment)
        }
        fromPouch.segmentCount = 0
    }
    
    static func copyAllSegments(from fromPouch: StochasticSplineReducerBucket,
                                to toPouch: StochasticSplineReducerBucket) {
        for segmentIndex in 0..<fromPouch.segmentCount {
            let segment = fromPouch.segments[segmentIndex]
            toPouch.addSegment(segment)
        }
    }
    
}
