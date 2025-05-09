//
//  StochasticSplineReducer+ReduceSingle.swift
//  Yo Mamma Be Ugly
//
//  Created by Nick Raptis on 12/3/24.
//

import Foundation

extension StochasticSplineReducer {
    
    // [S.R. Czech] 12-3-2024: This function works as intended.
    func populateTempbuckets_ReduceSingle(maxCombinedPouches: Int) {
        
        // We reset the temp pouch count to 0,
        // this we intend to populate.
        tempBucketCount = 0
        
        // We loop through all the zipper buckets...
        for bucketIndex in 0..<bucketCount {
            
            // Is this marked as visited?
            let zp_cur = buckets[bucketIndex]
            if zp_cur.isVisited == false {
                
                var indexFwd1 = bucketIndex + 1
                if indexFwd1 == bucketCount { indexFwd1 = 0 }
                
                // Will combining (current) and (forward 1) overflow?
                let zp_f_1 = buckets[indexFwd1]
                let combinedCountFwd = zp_cur.numberOfCombinedbuckets + zp_f_1.numberOfCombinedbuckets
                if combinedCountFwd <= maxCombinedPouches {
                    addTempBucket(bucket: zp_cur,
                                       bucketIndex: bucketIndex)
                }
            }
        }
    }
    
    // [S.R. Czech] 12-3-2024: This function works as intended.
    func executeCommand_ReduceSingle(numberOfPointsSampledForEachControlPoint: Int,
                                     tryCount: Int,
                                     maxCombinedPouches: Int,
                                     tolerance: Float) {
        
        let toleranceSquared = tolerance * tolerance
        
        // Mark all the zipper buckets as
        // not yet having been visited...
        for bucketIndex in 0..<bucketCount {
            let bucket = buckets[bucketIndex]
            bucket.isVisited = false
        }
        
        var KP_tryCount = 0
        var KP_attemptCount = 0
        var KP_successCount = 0
        var KP_failureCount = 0
        
        // Loop from 0 to tryCount.
        for _ in 0..<tryCount {
            
            KP_tryCount += 1
            
            // Did we underflow?
            if bucketCount <= Self.minBucketCount {
                break
            }
            
            // Load up the temporary zipper buckets.
            populateTempbuckets_ReduceSingle(maxCombinedPouches: maxCombinedPouches)
            
            // Did we find any temporary zipper buckets?
            if tempBucketCount <= 0 {
                break
            }
            
            // Pick a random starting index.
            let startIndex = Int.random(in: 0..<tempBucketCount)
            
            // We're going to keep visiting zipper
            // buckets until we end up reducing one
            // or we have exhausted the entire list...
            // Half A: From startIndex to EOL
            var isLoopingThroughoutbuckets = true
            var loopIndex = startIndex
            while (loopIndex < tempBucketCount) && (isLoopingThroughoutbuckets == true) {
                
                KP_attemptCount += 1
                
                // The zipper pouch and the index
                // from the master list..........
                let bucket = tempBuckets[loopIndex]
                let bucketIndex = tempBucketIndices[loopIndex]
                if attemptToReduceSingle(index: bucketIndex,
                                         numberOfPointsSampledForEachControlPoint: numberOfPointsSampledForEachControlPoint,
                                         toleranceSquared: toleranceSquared) {
                    
                    // We succeeded, stop checking more
                    // zipper buckets on this "try" iteration (outer loop).
                    isLoopingThroughoutbuckets = false
                    KP_successCount += 1
                } else {
                    
                    // We failed, mark this node as visited.
                    // We wil not re-visit the node unless
                    // one of the neighbors merges.
                    bucket.isVisited = true
                    loopIndex += 1
                    KP_failureCount += 1
                }
            }
            
            // We're going to keep visiting zipper
            // buckets until we end up reducing one
            // or we have exhausted the entire list...
            // Half B: From 0 to startIndex
            loopIndex = 0
            while (loopIndex < startIndex) && (isLoopingThroughoutbuckets == true) {
                
                KP_attemptCount += 1
                
                let bucket = tempBuckets[loopIndex]
                let bucketIndex = tempBucketIndices[loopIndex]
                
                if attemptToReduceSingle(index: bucketIndex,
                                         numberOfPointsSampledForEachControlPoint: numberOfPointsSampledForEachControlPoint,
                                         toleranceSquared: toleranceSquared) {
                    // We succeeded, stop checking more
                    // zipper buckets on this "try" iteration (outer loop).
                    isLoopingThroughoutbuckets = false
                    KP_successCount += 1
                } else {
                    // We failed, mark this node as visited.
                    // We wil not re-visit the node unless
                    // one of the neighbors merges.
                    bucket.isVisited = true
                    loopIndex += 1
                    KP_failureCount += 1
                }
            }
            
            if (isLoopingThroughoutbuckets == true) {
                // We did not succeeded on any
                // zipper pouch, there's nothing
                // left to check, so we can exit...
                break
            }
        }
    }
    
    //  Start: [a]...[bucketIndex]...[b]...[c]
    // Finish: [a]...[bucketIndex].........[c]
    // So, we need to check:
    //    [a].........[bucketIndex].........[c][s2]
    //    [ sample a ][             sample b           ]
    func attemptToReduceSingle(index: Int,
                               numberOfPointsSampledForEachControlPoint: Int,
                               toleranceSquared: Float) -> Bool {
        
        if index < 0 { return false }
        if index >= bucketCount { return false }
        
        // Reset all the test segments...
        testSegmentCountA = 0
        testSegmentCountB = 0
        
        // Reset all the test points...
        testPointCountA = 0
        testPointCountB = 0
        
        // The indices for the following:
        // ...[b1][self][f1][f2][f3]...
        var indexBck1 = index - 1
        if indexBck1 == -1 { indexBck1 = bucketCount - 1 }
        var indexFwd1 = index + 1
        if indexFwd1 == bucketCount { indexFwd1 = 0 }
        var indexFwd2 = indexFwd1 + 1
        if indexFwd2 == bucketCount { indexFwd2 = 0 }
        var indexFwd3 = indexFwd2 + 1
        if indexFwd3 == bucketCount { indexFwd3 = 0 }
        
        // Load up the internal spline with
        // every point except for (self + 1)
        internalSpline.removeAll(keepingCapacity: true)
        for bucketIndex in 0..<bucketCount {
            if (bucketIndex != indexFwd1) {
                let bucket = buckets[bucketIndex]
                internalSpline.addControlPoint(bucket.x,
                                               bucket.y)
            }
        }
        internalSpline.solve(closed: true)
        
        // The neighbors in question:
        // ...[b1][self][f1][f2][f3]...
        let zp_b_1 = buckets[indexBck1]
        let zp_cur = buckets[index]
        let zp_f_1 = buckets[indexFwd1]
        let zp_f_2 = buckets[indexFwd2]
        
        // Segments from b1..<self are test group A.
        for segmentIndex in 0..<zp_b_1.segmentCount {
            let segment = zp_b_1.segments[segmentIndex]
            addTestSegmentA(segment)
        }
        
        // Segments from self..<f1 are test group B.
        for segmentIndex in 0..<zp_cur.segmentCount {
            let segment = zp_cur.segments[segmentIndex]
            addTestSegmentB(segment)
        }
        
        // Segments from f1..<f2 are test group B.
        for segmentIndex in 0..<zp_f_1.segmentCount {
            let segment = zp_f_1.segments[segmentIndex]
            addTestSegmentB(segment)
        }
        
        // Segments from f2..<f3 are test group B.
        for segmentIndex in 0..<zp_f_2.segmentCount {
            let segment = zp_f_2.segments[segmentIndex]
            addTestSegmentB(segment)
        }
        
        // Calculate the new index and count,
        // which result from removing exactly
        // one zipper pouch...
        let newCount = bucketCount - 1
        let newIndex: Int
        if index == newCount {
            
            // [f1][n][n][n][n][b1][i] // count = 7, index = 6
            // [n][n][n][n][b1][i]     // count = 6, index = 5
            
            newIndex = (index - 1)
        } else {
            
            // [n][n][n][n][b1][i][f1] // count = 7, index = 5
            // [n][n][n][n][b1][i]     // count = 6, index = 5
            
            // [i][f1][n][n][n][i][b1] // count = 7, index = 0
            // [i][n][n][n][i][b1]     // count = 6, index = 0
            
            newIndex = index
        }
        
        // The *NEW* indices for the following:
        // ...[b1][self][f1][f2]...
        var newIndexBck1 = newIndex - 1
        if newIndexBck1 == -1 { newIndexBck1 = newCount - 1 }
        var newIndexFwd1 = newIndex + 1
        if newIndexFwd1 == newCount { newIndexFwd1 = 0 }
        var newIndexBck2 = newIndexBck1 - 1
        if newIndexBck2 == -1 { newIndexBck2 = newCount - 1 }
        var newIndexFwd2 = newIndexFwd1 + 1
        if newIndexFwd2 == newCount { newIndexFwd2 = 0 }
        
        // Points from b1..<self (in new spline) are test group A.
        let count_b_2 = zp_b_1.numberOfCombinedbuckets * numberOfPointsSampledForEachControlPoint
        for index in 1..<count_b_2 {
            let percent = Float(index) / Float(count_b_2)
            let x = internalSpline.getX(index: newIndexBck1, percent: percent)
            let y = internalSpline.getY(index: newIndexBck1, percent: percent)
            addPointTestPointsA(x: x,
                                y: y)
        }
        
        // Points from self..<f1 (in new spline) are test group B.
        // It should be noted that self and f1 are combined into self...
        let numberOfCombinedbucketsTarget = zp_cur.numberOfCombinedbuckets + zp_f_1.numberOfCombinedbuckets
        let count_cur = numberOfCombinedbucketsTarget * numberOfPointsSampledForEachControlPoint
        for index in 1..<count_cur {
            let percent = Float(index) / Float(count_cur)
            let x = internalSpline.getX(index: newIndex, percent: percent)
            let y = internalSpline.getY(index: newIndex, percent: percent)
            addPointTestPointsB(x: x,
                                y: y)
        }
            
        // Points from f2..<f3 (in new spline) are test group B.
        let count_f_2 = zp_f_2.numberOfCombinedbuckets * numberOfPointsSampledForEachControlPoint
        for index in 1..<count_f_2 {
            let percent = Float(index) / Float(count_f_2)
            let x = internalSpline.getX(index: newIndexFwd1, percent: percent)
            let y = internalSpline.getY(index: newIndexFwd1, percent: percent)
            addPointTestPointsB(x: x,
                                y: y)
        }
        
        // Now we cross compare the distances from
        // Segment List A to Point List A.........
        // If we're farther than threshold, it's a bad choice!
        var error = false
        let distanceA = getMaximumDistanceFromTestPointsToSegmentsA(isError: &error)
        if error { return false }
        if distanceA > toleranceSquared { return false }
        
        // Now we cross compare the distances from
        // Segment List A to Point List A.........
        // If we're farther than threshold, it's a bad choice!
        let distanceB = getMaximumDistanceFromTestPointsToSegmentsB(isError: &error)
        if error { return false }
        if distanceB > toleranceSquared { return false }
        
        // We transfer all the line segments from f1 to self...
        StochasticSplineReducerBucket.transferAllSegments(from: zp_f_1, to: zp_cur)
        
        // We "combine" self and f1...
        zp_cur.numberOfCombinedbuckets += zp_f_1.numberOfCombinedbuckets
        
        // We remove f1...
        removeBucketOne(index: indexFwd1)
        
        // We unvisit both neighbors
        // of the new self...
        unvisitBothNeighbors(bucketIndex: newIndex)
        
        return true
    }
    
}
