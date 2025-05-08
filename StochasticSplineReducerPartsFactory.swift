//
//  StochasticSplineReducerPartsFactory.swift
//  Yo Mamma Be Ugly
//
//  Created by Nick Raptis on 11/30/24.
//

import Foundation

public class StochasticSplineReducerPartsFactory {
    
    public nonisolated(unsafe) static let shared = StochasticSplineReducerPartsFactory()
    
    private init() {
        
    }
    
    public func dispose() {
        segments.removeAll(keepingCapacity: false)
        segmentCount = 0
        

        buckets.removeAll(keepingCapacity: false)
        bucketCount = 0
    }
    
    ////////////////
    ///
    ///
    private var segments = [StochasticSplineReducerSegment]()
    var segmentCount = 0
    func depositSegment(_ segment: StochasticSplineReducerSegment) {
        while segments.count <= segmentCount {
            segments.append(segment)
        }
        segments[segmentCount] = segment
        segmentCount += 1
    }
    func withdrawSegment() -> StochasticSplineReducerSegment {
        if segmentCount > 0 {
            segmentCount -= 1
            return segments[segmentCount]
        }
        return StochasticSplineReducerSegment()
    }
    ///
    ///
    ////////////////
    
    
    ////////////////
    ///
    ///
    var buckets = [StochasticSplineReducerBucket]()
    var bucketCount = 0
    
    func depositBucket(_ bucket: StochasticSplineReducerBucket) {
        while buckets.count <= bucketCount {
            buckets.append(bucket)
        }
        buckets[bucketCount] = bucket
        bucketCount += 1
    }
    func withdrawBucket() -> StochasticSplineReducerBucket {
        if bucketCount > 0 {
            bucketCount -= 1
            return buckets[bucketCount]
        }
        return StochasticSplineReducerBucket()
    }
    
    ///
    ///
    ////////////////
    
    
    
}
