//
//  StochasticSplineReducer.swift
//  Yo Mamma Be Ugly
//
//  Created by Nick Raptis on 11/30/24.
//

import Foundation
import MathKit

public class StochasticSplineReducer {
    
    public init() {
        
    }
    
    static let minBucketCount = 8
    static let minNumberOfSamples = 3
    
    var segments = [StochasticSplineReducerSegment]()
    var segmentCount = 0
    
    var testSegmentsA = [StochasticSplineReducerSegment]()
    var testSegmentCountA = 0
    
    var testSegmentsB = [StochasticSplineReducerSegment]()
    var testSegmentCountB = 0
    
    var buckets = [StochasticSplineReducerBucket]()
    var bucketCount = 0
    
    var testBuckets = [StochasticSplineReducerBucket]()
    var _testBucketCapacity = 0
    var _testBucketCount = 0
    
    var tempBuckets = [StochasticSplineReducerBucket]()
    var tempBucketIndices = [Int]()
    var tempBucketCount = 0
    
    var testPointCountA = 0
    var testPointCapacityA = 0
    var testPointsXA = [Float]()
    var testPointsYA = [Float]()
    
    var testPointCountB = 0
    var testPointCapacityB = 0
    var testPointsXB = [Float]()
    var testPointsYB = [Float]()
    
    var internalSpline = MathKit.AutomaticSpline()
    
    let pathChopper = StochasticSplineReducerPathChopper()
    let exploredPool = StochasticSplineReducerExploredPool()
    
    var chopperBestPath = [Int]()
    var chopperBestPathCount = 0
    
    public func clear() {
        testPointCountA = 0
        testPointCountB = 0
        testSegmentCountA = 0
        testSegmentCountB = 0
        
        purgeBuckets()
        purgeSegments()
        purgeTestBuckets()
    }
    
    public func reduce(inputSpline: MathKit.ManualSpline,
                       outputSpline: MathKit.ManualSpline,
                       numberOfPointsSampledForEachControlPoint: Int,
                       programmableCommands: [StochasticSplineReducerCommand]) {
        
        clear()
        
        readInputSpline(inputSpline: inputSpline,
                        numberOfPointsSampledForEachControlPoint: numberOfPointsSampledForEachControlPoint)
        
        for programmableCommand in programmableCommands {
            switch programmableCommand {
            case .reduceFrontAndBack(let reductionData):
                executeCommand_ReduceDouble(numberOfPointsSampledForEachControlPoint: numberOfPointsSampledForEachControlPoint,
                                            tryCount: reductionData.tryCount,
                                            maxCombinedPouches: reductionData.maxCombinedPouches,
                                            tolerance: reductionData.tolerance)
            case .reduceBackOnly(let reductionData):
                executeCommand_ReduceSingle(numberOfPointsSampledForEachControlPoint: numberOfPointsSampledForEachControlPoint,
                                            tryCount: reductionData.tryCount,
                                            maxCombinedPouches: reductionData.maxCombinedPouches,
                                            tolerance: reductionData.tolerance)
            case .chopper(let reductionData):
                executeCommand_ReduceChopper(numberOfPointsSampledForEachControlPoint: numberOfPointsSampledForEachControlPoint,
                                             minimumStep: reductionData.minimumStep,
                                             maximumStep: reductionData.maximumStep,
                                             tryCount: reductionData.tryCount,
                                             dupeOrInvalidRetryCount: reductionData.dupeOrInvalidRetryCount,
                                             tolerance: reductionData.tolerance)
            }
        }
        
        outputSpline.removeAll(keepingCapacity: true)
        for bucketIndex in 0..<bucketCount {
            let bucket = buckets[bucketIndex]
            outputSpline.addControlPoint(bucket.x, bucket.y)
        }
        outputSpline.solve(closed: true)
        
        testPointCountA = 0
        testPointCountB = 0
        testSegmentCountA = 0
        testSegmentCountB = 0
    }
    
    func unvisitBothNeighbors(bucketIndex: Int) {
        if bucketIndex < 0 {
            print("FATAL: Attempting to unvisit bucketIndex = \(bucketIndex) / \(bucketCount)")
            return
        }
        if bucketIndex >= bucketCount {
            print("FATAL: Attempting to unvisit bucketIndex = \(bucketIndex) / \(bucketCount)")
            return
        }
        var indexBck1 = bucketIndex - 1
        if indexBck1 == -1 { indexBck1 = bucketCount - 1 }
        var indexFwd1 = bucketIndex + 1
        if indexFwd1 == bucketCount { indexFwd1 = 0 }
        buckets[indexBck1].isVisited = false
        buckets[indexFwd1].isVisited = false
    }
    
}
