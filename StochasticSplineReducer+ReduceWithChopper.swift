//
//  StochasticSplineReducer+ReduceWithChopper.swift
//  Yo Mamma Be Ugly
//
//  Created by Nick Raptis on 12/4/24.
//

import Foundation

extension StochasticSplineReducer {
    
    // Here we would need to account for self-intersect.
    func reduceChopper(numberOfPointsSampledForEachControlPoint: Int,
                       bestDistanceSquaredSoFar: Float) -> StochasticSplineReducerResponse {
        
        internalSpline.removeAll(keepingCapacity: true)
        for testBucketIndex in 0..<_testBucketCount {
            let testBucket = testBuckets[testBucketIndex]
            internalSpline.addControlPoint(testBucket.x, testBucket.y)
        }
        internalSpline.solve(closed: true)
        
        var greatestDistanceSquaredSoFar = Float(0.0)
        
        for testBucketIndex in 0..<_testBucketCount {
            
            testPointCountA = 0
            testSegmentCountA = 0
            
            let testBucket = testBuckets[testBucketIndex]
            for segmentIndex in 0..<testBucket.segmentCount {
                let segment = testBucket.segments[segmentIndex]
                addTestSegmentA(segment)
            }
            
            let numberOfCombinedBuckets = testBucket.numberOfCombinedbuckets
            let numberOfPoints = numberOfCombinedBuckets * numberOfPointsSampledForEachControlPoint
            for pointIndex in 1..<numberOfPoints {
                let percent = Float(pointIndex) / Float(numberOfPoints)
                let x = internalSpline.getX(index: testBucketIndex, percent: percent)
                let y = internalSpline.getY(index: testBucketIndex, percent: percent)
                addPointTestPointsA(x: x, y: y)
            }
            
            var error = false
            let distanceA = getMaximumDistanceFromTestPointsToSegmentsA(isError: &error)
            if error { return StochasticSplineReducerResponse.failure }
            if distanceA > bestDistanceSquaredSoFar { return .overweight }
            if distanceA > greatestDistanceSquaredSoFar { greatestDistanceSquaredSoFar = distanceA }
        }
        
        chopperBestPathCount = pathChopper.pathCount
        while chopperBestPath.count < chopperBestPathCount {
            chopperBestPath.append(0)
        }
        for pathIndex in 0..<pathChopper.pathCount {
            chopperBestPath[pathIndex] = pathChopper.path[pathIndex]
        }
        return StochasticSplineReducerResponse.validNewBestMatch(greatestDistanceSquaredSoFar)
    }
        
    func executeCommand_ReduceChopper(numberOfPointsSampledForEachControlPoint: Int,
                                      minimumStep: Int,
                                      maximumStep: Int,
                                      tryCount: Int,
                                      dupeOrInvalidRetryCount: Int,
                                      tolerance: Float) {
        
        for bucketIndex in 0..<bucketCount {
            let bucket = buckets[bucketIndex]
            if bucket.numberOfCombinedbuckets > 1 {
                return
            }
        }
        
        let toleranceSquared = tolerance * tolerance
        
        _ = pathChopper.build(pathLength: bucketCount,
                              minimumStep: minimumStep,
                              maximumStep: maximumStep)
        
        exploredPool.clear()
        
        chopperBestPathCount = 0
        
        var KP_tryCount = 0
        var KP_attemptCount = 0
        var KP_invalidRetryCount = 0
        var KP_dupeRetryCount = 0
        var KP_successCount = 0
        var KP_failureCount = 0
        
        var bestDistanceSquaredSoFar = Float(100_000_000.0)
        
        for _ in 0..<tryCount {
            KP_tryCount += 1
            
            var isValidPath = false
            for _ in 0..<dupeOrInvalidRetryCount {
                pathChopper.solve()
                if pathChopper.pathCount < 3 {
                    KP_invalidRetryCount += 1
                    continue
                }
                if exploredPool.contains(chopper: pathChopper) {
                    KP_dupeRetryCount += 1
                    continue
                }
                
                isValidPath = true
                break
            }
            
            if isValidPath == false {
                KP_failureCount += 1
                break
            }
            
            KP_attemptCount += 1
            
            exploredPool.ingest(chopper: pathChopper)
            
            if !loadUpTestBucketsFromPathChopperPath() {
                print("FATAL ERROR: We should not fail to load the test buckets")
                KP_failureCount += 1
                continue
            }
            
            let response = reduceChopper(numberOfPointsSampledForEachControlPoint: numberOfPointsSampledForEachControlPoint,
                                         bestDistanceSquaredSoFar: bestDistanceSquaredSoFar)
            switch response {
            case .validNewBestMatch(let distanceSquared):
                bestDistanceSquaredSoFar = distanceSquared
                KP_successCount += 1
            case .overweight:
                KP_failureCount += 1
            case .failure:
                KP_failureCount += 1
            }
        }
        
        if chopperBestPathCount > 0 && bestDistanceSquaredSoFar < toleranceSquared {
            loadUpTestBucketsFromPathBestPath()
            transferTestBucketsToBuckets()
            
        }
    }
    
    func transferTestBucketsToBuckets() {
        
        purgeBuckets()
        
        for bucketIndex in 0..<_testBucketCount {
            let bucket = testBuckets[bucketIndex]
            addBucket(bucket: bucket)
        }
        
        for bucketIndex in _testBucketCount..<_testBucketCapacity {
            StochasticSplineReducerPartsFactory.shared.depositBucket(testBuckets[bucketIndex])
        }
        
        _testBucketCapacity = 0
        _testBucketCount = 0
        
    }
    
    // [S.R. Czech] 12-4-2024: This function works as intended.
    func loadUpTestBucketsFromPathChopperPath() -> Bool {
        
        _testBucketCount = pathChopper.pathCount
        
        if pathChopper.pathCount < 3 {
            print("FATAL: pathChopper.pathCount < 3 (\(pathChopper.pathCount))")
            return false
        }
        
        // Ensure we have enough test buckets for
        // the path. There should be a minimum of
        // a 1-1 mapping from path => testBuckets...
        while _testBucketCapacity < pathChopper.pathCount {
            let testBucket = StochasticSplineReducerPartsFactory.shared.withdrawBucket()
            addTestBucket(bucket: testBucket)
        }
        
        for pathIndex in 0..<pathChopper.pathCount {
            let testBucket = testBuckets[pathIndex]
            testBucket.segmentCount = 0
        }
        
        // Loop through the entire path...
        for pathIndex in 0..<pathChopper.pathCount {
            
            // Test bucket : path
            // 1 : 1
            let testBucket = testBuckets[pathIndex]
            
            // We are going to loop
            // bucketIndex..<nextBucketIndex
            var bucketIndex = pathChopper.path[pathIndex]
            
            // Keep track of the original index...
            testBucket.originalIndex = bucketIndex
            
            // Move the x and y to original x and y
            testBucket.x = buckets[bucketIndex].x
            testBucket.y = buckets[bucketIndex].y
            
            // Reset the numberOfCombinedbuckets,
            // this will be computed in loop.
            testBucket.numberOfCombinedbuckets = 0
            
            // The next path index.
            let nextPathIndex: Int
            if pathIndex == (pathChopper.pathCount - 1) {
                nextPathIndex = 0
            } else {
                nextPathIndex = pathIndex + 1
            }
            
            // This will be the index of the last
            // "original" bucket to use.
            // path[pathIndex]..<finalBucketIndex
            let finalBucketIndex = pathChopper.path[nextPathIndex]
            
            while bucketIndex != finalBucketIndex {
                
                // "Combine" the number two buckets.
                testBucket.numberOfCombinedbuckets += buckets[bucketIndex].numberOfCombinedbuckets
                
                // "Combine" also the line segments.
                StochasticSplineReducerBucket.copyAllSegments(from: buckets[bucketIndex],
                                                              to: testBucket)
                
                // Loop around the end...
                bucketIndex += 1
                if bucketIndex == bucketCount {
                    bucketIndex = 0
                }
            }
        }
        
        return true
    }
    
    func loadUpTestBucketsFromPathBestPath() {
        
        
        _testBucketCount = chopperBestPathCount
        
        // Ensure we have enough test buckets for
        // the best chopper path. There should be a minimum
        // of a 1-1 mapping from path => testBuckets.......
        while _testBucketCapacity < chopperBestPathCount {
            let testBucket = StochasticSplineReducerPartsFactory.shared.withdrawBucket()
            addTestBucket(bucket: testBucket)
        }
        
        for pathIndex in 0..<chopperBestPathCount {
            let testBucket = testBuckets[pathIndex]
            testBucket.segmentCount = 0
        }
        
        // Loop through the entire path...
        for pathIndex in 0..<chopperBestPathCount {
            
            // Test bucket : path
            // 1 : 1
            let testBucket = testBuckets[pathIndex]
            
            // We are going to loop
            // bucketIndex..<nextBucketIndex
            var bucketIndex = chopperBestPath[pathIndex]
            
            // Keep track of the original index...
            testBucket.originalIndex = bucketIndex
            
            // Move the x and y to original x and y
            testBucket.x = buckets[bucketIndex].x
            testBucket.y = buckets[bucketIndex].y
            
            // Reset the numberOfCombinedbuckets,
            // this will be computed in loop.
            testBucket.numberOfCombinedbuckets = 0
            
            // The next path index.
            let nextPathIndex: Int
            if pathIndex == (chopperBestPathCount - 1) {
                nextPathIndex = 0
            } else {
                nextPathIndex = pathIndex + 1
            }
            
            // This will be the index of the last
            // "original" bucket to use.
            // path[pathIndex]..<finalBucketIndex
            let finalBucketIndex = chopperBestPath[nextPathIndex]
            
            while bucketIndex != finalBucketIndex {
                
                // "Combine" the number two buckets.
                testBucket.numberOfCombinedbuckets += buckets[bucketIndex].numberOfCombinedbuckets
                
                // "Combine" also the line segments.
                StochasticSplineReducerBucket.copyAllSegments(from: buckets[bucketIndex],
                                                              to: testBucket)
                
                // Loop around the end...
                bucketIndex += 1
                if bucketIndex == bucketCount {
                    bucketIndex = 0
                }
            }
        }
    }
}
