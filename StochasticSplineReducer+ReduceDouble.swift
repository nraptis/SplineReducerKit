//
//  StochasticSplineReducer+ReduceDouble.swift
//  Yo Mamma Be Ugly
//
//  Created by Nick Raptis on 12/3/24.
//

import Foundation

extension StochasticSplineReducer {
    
    // [S.R. Czech] 12-3-2024: This function works as intended.
    func populateTempbuckets_ReduceDouble(maxCombinedPouches: Int) {
        
        // We reset the temp pouch count to 0,
        // this we intend to populate.
        tempBucketCount = 0
        
        // We loop through all the zipper buckets...
        for bucketIndex in 0..<bucketCount {
            
            // Is this marked as visited?
            let zp_cur = buckets[bucketIndex]
            if zp_cur.isVisited == false {
                
                var indexBck1 = bucketIndex - 1
                if indexBck1 == -1 { indexBck1 = bucketCount - 1 }
                var indexBck2 = indexBck1 - 1
                if indexBck2 == -1 { indexBck2 = bucketCount - 1 }
                
                // Will combining (back 1) and (back 2) overflow?
                let zp_b_2 = buckets[indexBck2]
                let zp_b_1 = buckets[indexBck1]
                let combinedCountBck = zp_b_2.numberOfCombinedbuckets + zp_b_1.numberOfCombinedbuckets
                
                if combinedCountBck <= maxCombinedPouches {
                    
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
    }
    
    // [S.R. Czech] 12-3-2024: This function works as intended.
    func executeCommand_ReduceDouble(numberOfPointsSampledForEachControlPoint: Int,
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
        
        
        // Alright, we want a super tight loop here... As tight as it gets...
        // Yet, statistically, we do not want to weight incorrectly.
        
        for _ in 0..<tryCount {
            
            KP_tryCount += 1
            
            // Did we underflow?
            if bucketCount <= Self.minBucketCount { break }
            
            // Load up the temporary zipper buckets.
            populateTempbuckets_ReduceDouble(maxCombinedPouches: maxCombinedPouches)
            
            // Did we find any temporary zipper buckets?
            if tempBucketCount <= 0 { break }
            
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
                
                if attemptToReduceDouble(index: bucketIndex,
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
                
                if attemptToReduceDouble(index: bucketIndex,
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
    
    
    // [S.R. Czech] 12-3-2024: This function works as intended.
    //
    //  Start: [a]...[b]...[bucketIndex]...[c]...[d]
    // Finish: [a].........[bucketIndex].........[d]
    // So, we need to check:
    //    [s1] [a].........[bucketIndex].........[d][s2]
    //    [    sample a   ][             sample b           ]
    func attemptToReduceDouble(index: Int,
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
        // ...[b3][b2][b1][self][f1][f2][f3]...
        var indexBck1 = index - 1
        if indexBck1 == -1 { indexBck1 = bucketCount - 1 }
        var indexFwd1 = index + 1
        if indexFwd1 == bucketCount { indexFwd1 = 0 }
        var indexBck2 = indexBck1 - 1
        if indexBck2 == -1 { indexBck2 = bucketCount - 1 }
        var indexFwd2 = indexFwd1 + 1
        if indexFwd2 == bucketCount { indexFwd2 = 0 }
        var indexBck3 = indexBck2 - 1
        if indexBck3 == -1 { indexBck3 = bucketCount - 1 }
        var indexFwd3 = indexFwd2 + 1
        if indexFwd3 == bucketCount { indexFwd3 = 0 }
        
        // Load up the internal spline with
        // every point except for (self + 1) and (self - 1)
        internalSpline.removeAll(keepingCapacity: true)
        for bucketIndex in 0..<bucketCount {
            if (bucketIndex != indexBck1) && (bucketIndex != indexFwd1) {
                let bucket = buckets[bucketIndex]
                internalSpline.addControlPoint(bucket.x,
                                               bucket.y)
            }
        }
        internalSpline.solve(closed: true)
        
        // The neighbors in question:
        // ...[b3][b2][b1][self][f1][f2][f3]...
        let zp_b_3 = buckets[indexBck3]
        let zp_b_2 = buckets[indexBck2]
        let zp_b_1 = buckets[indexBck1]
        let zp_cur = buckets[index]
        let zp_f_1 = buckets[indexFwd1]
        let zp_f_2 = buckets[indexFwd2]
        
        // Segments from b3..<b2 are test group A.
        for segmentIndex in 0..<zp_b_3.segmentCount {
            let segment = zp_b_3.segments[segmentIndex]
            addTestSegmentA(segment)
        }
        
        // Segments from b2..<b1 are test group A.
        for segmentIndex in 0..<zp_b_2.segmentCount {
            let segment = zp_b_2.segments[segmentIndex]
            addTestSegmentA(segment)
        }
        
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
        // two zipper buckets...
        let newCount = bucketCount - 2
        let newIndex: Int
        if indexBck1 > index {
            // We did remove from the front of the list, the new index should be exactly the same...
            // and in fact, this is always the case for 0.
            newIndex = index
        } else {
            // We do not need to consider the 0 case.
            if index >= newCount {
                // We removed TWO indices, these are the two cases:
                
                // [f1][n][n][n][n][b1][i] // count = 7, index = 6
                // [n][n][n][n][i]         // count = 5, index = 4
                
                // [n][n][n][n][b1][i][f1] // count = 7, index = 5
                // [n][n][n][n][i]         // count = 5, index = 4
                
                newIndex = newCount - 1
                
            } else {
                // In this case, since we removed a
                // preceeding index, we step back one.
                newIndex = index - 1
            }
        }
        
        // The *NEW* indices for the following:
        // ...[b2][b1][self][f1][f2]...
        
        var newIndexBck1 = newIndex - 1
        if newIndexBck1 == -1 { newIndexBck1 = newCount - 1 }
        var newIndexFwd1 = newIndex + 1
        if newIndexFwd1 == newCount { newIndexFwd1 = 0 }
        var newIndexBck2 = newIndexBck1 - 1
        if newIndexBck2 == -1 { newIndexBck2 = newCount - 1 }
        var newIndexFwd2 = newIndexFwd1 + 1
        if newIndexFwd2 == newCount { newIndexFwd2 = 0 }
        
        // Points from b2..<b1 (in new spline) are test group A.
        // It should be noted that b3 from the old spline is b2
        // in the new spline... So, we use zp_b_3 as reference...
        let count_b_3 = zp_b_3.numberOfCombinedbuckets * numberOfPointsSampledForEachControlPoint
        for index in 1..<count_b_3 {
            let percent = Float(index) / Float(count_b_3)
            let x = internalSpline.getX(index: newIndexBck2, percent: percent)
            let y = internalSpline.getY(index: newIndexBck2, percent: percent)
            addPointTestPointsA(x: x,
                                y: y)
        }
        
        // Points from b1..<self (in new spline) are test group A.
        // It should be noted that b2 and b1 are combined into b1...
        let numberOfCombinedbucketsBack2 = zp_b_2.numberOfCombinedbuckets + zp_b_1.numberOfCombinedbuckets
        let count_b_2 = numberOfCombinedbucketsBack2 * numberOfPointsSampledForEachControlPoint
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
        
        // Points from f2..<f2 (in new spline) are test group B.
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
        
        // We transfer all the line segments from b1 to b2...
        StochasticSplineReducerBucket.transferAllSegments(from: zp_b_1, to: zp_b_2)
        
        // We "combine" b1 and b2...
        zp_b_2.numberOfCombinedbuckets += zp_b_1.numberOfCombinedbuckets
        
        // We transfer all the line segments from f1 to self...
        StochasticSplineReducerBucket.transferAllSegments(from: zp_f_1, to: zp_cur)
        
        // We "combine" self and f1...
        zp_cur.numberOfCombinedbuckets += zp_f_1.numberOfCombinedbuckets
        
        // We remove b1 and f1...
        removeBucketTwo(index1: indexBck1, index2: indexFwd1)
        
        // We unvisit both neighbors
        // of the new self...
        
        unvisitBothNeighbors(bucketIndex: newIndex)
        return true
    }
}
