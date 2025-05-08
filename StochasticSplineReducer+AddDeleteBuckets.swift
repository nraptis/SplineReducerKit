//
//  StochasticSplineReducer+AddDeletebuckets.swift
//  Yo Mamma Be Ugly
//
//  Created by Nick Raptis on 11/30/24.
//

import Foundation

extension StochasticSplineReducer {
    
    // @Precondition: index1 != index2
    // @Precondition: index1 in range 0..<bucketCount
    // @Precondition: index2 in range 0..<bucketCount
    // @Precondition: bucketCount >= 2
    func removeBucketTwo(index1: Int, index2: Int) {
        StochasticSplineReducerPartsFactory.shared.depositBucket(buckets[index1])
        StochasticSplineReducerPartsFactory.shared.depositBucket(buckets[index2])
        
        let lowerIndex = min(index1, index2)
        let higherIndex = max(index1, index2) - 1
        
        var bucketIndex = lowerIndex
        while bucketIndex < higherIndex {
            buckets[bucketIndex] = buckets[bucketIndex + 1]
            bucketIndex += 1
        }
        
        let bucketCount2 = bucketCount - 2
        while bucketIndex < bucketCount2 {
            buckets[bucketIndex] = buckets[bucketIndex + 2]
            bucketIndex += 1
        }
        bucketCount -= 2
    }
    
    // @Precondition: index in range 0..<bucketCount
    // @Precondition: bucketCount >= 1
    func removeBucketOne(index: Int) {
        StochasticSplineReducerPartsFactory.shared.depositBucket(buckets[index])
        let bucketCount1 = bucketCount - 1
        var bucketIndex = index
        while bucketIndex < bucketCount1 {
            buckets[bucketIndex] = buckets[bucketIndex + 1]
            bucketIndex += 1
        }
        bucketCount -= 1
    }
    
    func purgeBuckets() {
        for bucketIndex in 0..<bucketCount {
            let bucket = buckets[bucketIndex]
            StochasticSplineReducerPartsFactory.shared.depositBucket(bucket)
        }
        bucketCount = 0
    }
    
    func addBucket(bucket: StochasticSplineReducerBucket) {
        while buckets.count <= bucketCount {
            buckets.append(bucket)
        }
        buckets[bucketCount] = bucket
        bucketCount += 1
    }
    
    func purgeTestBuckets() {
        for bucketIndex in 0..<_testBucketCapacity {
            let bucket = testBuckets[bucketIndex]
            StochasticSplineReducerPartsFactory.shared.depositBucket(bucket)
        }
        _testBucketCapacity = 0
        _testBucketCount = 0
    }
    
    // Note: We're 
    func addTestBucket(bucket: StochasticSplineReducerBucket) {
        while testBuckets.count <= _testBucketCapacity {
            testBuckets.append(bucket)
        }
        testBuckets[_testBucketCapacity] = bucket
        _testBucketCapacity += 1
    }
    
    func addTempBucket(bucket: StochasticSplineReducerBucket, bucketIndex: Int) {
        while tempBuckets.count <= tempBucketCount {
            tempBuckets.append(bucket)
        }
        while tempBucketIndices.count <= tempBucketCount {
            tempBucketIndices.append(bucketIndex)
        }
        
        tempBuckets[tempBucketCount] = bucket
        tempBucketIndices[tempBucketCount] = bucketIndex
        
        tempBucketCount += 1
    }
    
}
