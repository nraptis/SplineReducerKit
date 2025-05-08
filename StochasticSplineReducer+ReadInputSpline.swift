//
//  StochasticSplineReducer+ReadInputSpline.swift
//  Yo Mamma Be Ugly
//
//  Created by Nick Raptis on 12/2/24.
//

import Foundation
import MathKit

extension StochasticSplineReducer {
    
    // [S.R. Czech] 12-3-2024: This function works as intended.
    func readInputSpline(inputSpline: MathKit.ManualSpline,
                         numberOfPointsSampledForEachControlPoint: Int) {
        
        if numberOfPointsSampledForEachControlPoint < StochasticSplineReducer.minNumberOfSamples { return }
        
        // We make a zipper pouch for each
        // control point on the input spline.
        let maxIndex = inputSpline.maxIndex
        
        // Did we underflow?
        if maxIndex < Self.minBucketCount { return }
        
        for splineIndex in 0..<maxIndex {
            let bucket = StochasticSplineReducerPartsFactory.shared.withdrawBucket()
            bucket.segmentCount = 0
            addBucket(bucket: bucket)
            bucket.x = inputSpline._x[splineIndex]
            bucket.y = inputSpline._y[splineIndex]
        }
        
        // We're going to sample N points
        // for each control point........
        let testPointsCount1 = (numberOfPointsSampledForEachControlPoint - 1)
        let testPointsCount1f = Float(testPointsCount1)
        
        for bucketIndex in 0..<bucketCount {
            let bucket = buckets[bucketIndex]
            
            // We have not combined with any
            // pouches, this is the initial state...
            bucket.numberOfCombinedbuckets = 1
            
            // We loop N-1 times, adding the
            // line segments to each pouch...
            var testPointsIndex = 1
            var previousX = inputSpline._x[bucketIndex]
            var previousY = inputSpline._y[bucketIndex]
            for percentIndex in 1..<numberOfPointsSampledForEachControlPoint {
                let percent = Float(percentIndex) / testPointsCount1f
                let currentX = inputSpline.getX(index: bucketIndex, percent: percent)
                let currentY = inputSpline.getY(index: bucketIndex, percent: percent)
                
                let segment = StochasticSplineReducerPartsFactory.shared.withdrawSegment()
                
                // This (spline reducer) retains the segment.
                addSegment(segment)
                
                // This (zipper pouch) holds a reference.
                bucket.addSegment(segment)
                
                segment.x1 = previousX
                segment.y1 = previousY
                
                segment.x2 = currentX
                segment.y2 = currentY
                
                segment.precompute()
                
                previousX = currentX
                previousY = currentY
                
                testPointsIndex += 1
            }
        }
    }
}
