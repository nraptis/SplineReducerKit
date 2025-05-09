//
//  StochasticSplineReducer+SampleA.swift
//  Yo Mamma Be Ugly
//
//  Created by Nick Raptis on 12/2/24.
//

import Foundation
import MathKit

extension StochasticSplineReducer {
    
    // [S.R. Czech] 12-3-2024: This function works as intended.
    func addPointTestPointsA(x: Float, y: Float) {
        if testPointCountA >= testPointCapacityA {
            reserveCapacityTestPointsA(minimumCapacity: testPointCountA + (testPointCountA >> 1) + 1)
        }
        testPointsXA[testPointCountA] = x
        testPointsYA[testPointCountA] = y
        testPointCountA += 1
    }
    
    // [S.R. Czech] 12-3-2024: This function works as intended.
    private func reserveCapacityTestPointsA(minimumCapacity: Int) {
        if minimumCapacity > testPointCapacityA {
            testPointsXA.reserveCapacity(minimumCapacity)
            testPointsYA.reserveCapacity(minimumCapacity)
            while testPointsXA.count < minimumCapacity {
                testPointsXA.append(0.0)
            }
            while testPointsYA.count < minimumCapacity {
                testPointsYA.append(0.0)
            }
            testPointCapacityA = minimumCapacity
        }
    }
    
    // [S.R. Czech] 12-3-2024: This function works as intended.
    func getMaximumDistanceFromTestPointsToSegmentsA(isError: inout Bool) -> Float {
        
        if testPointCountA <= 2 {
            isError = true
            return Float.nan
        }
        
        if testSegmentCountA <= 2 {
            isError = true
            return Float.nan
        }
        
        var result = Float(0.0)
        var pointIndexA = 1
        while pointIndexA < testPointCountA {
            let x = testPointsXA[pointIndexA]
            let y = testPointsYA[pointIndexA]
            var minDistanceSquared = Float(100_000_000.0)
            for segmentIndex in 0..<testSegmentCountA {
                let segment = testSegmentsA[segmentIndex]
                let distanceSquared = segment.distanceSquaredToClosestPoint(x, y)
                if distanceSquared < minDistanceSquared {
                    minDistanceSquared = distanceSquared
                }
            }
            if minDistanceSquared > result {
                result = minDistanceSquared
            }
            pointIndexA += 1
        }
        
        isError = false
        return result
    }
    
    // [S.R. Czech] 12-3-2024: This function works as intended.
    func addTestSegmentA(_ segment: StochasticSplineReducerSegment) {
        while testSegmentsA.count <= testSegmentCountA {
            testSegmentsA.append(segment)
        }
        testSegmentsA[testSegmentCountA] = segment
        testSegmentCountA += 1
    }
    
    // [S.R. Czech] 12-3-2024: TODO: This is not verified and not used currently.
    func isTestPointsComplexA() -> Bool {
        
        if testPointCountA > 3 {
            
            var seekIndex = 0
            let seekCeiling = (testPointCountA - 2)
            let checkCeiling = (testPointCountA - 1)
            
            while seekIndex < seekCeiling {
                
                // we check if
                // seekIndex, seekIndex + 1
                // collide with
                // seekIndex + 2...end-1
                // seekIndex + 3...end
                
                let l1_x1 = testPointsXA[seekIndex]
                let l1_y1 = testPointsYA[seekIndex]
                let l1_x2 = testPointsXA[seekIndex + 1]
                let l1_y2 = testPointsYA[seekIndex + 1]
                var checkIndex = seekIndex + 2
                while checkIndex < checkCeiling {
                    let l2_x1 = testPointsXA[checkIndex]
                    let l2_y1 = testPointsYA[checkIndex]
                    let l2_x2 = testPointsXA[checkIndex + 1]
                    let l2_y2 = testPointsYA[checkIndex + 1]
                    if Math.lineSegmentIntersectsLineSegment(line1Point1X: l1_x1,
                                                             line1Point1Y: l1_y1,
                                                             line1Point2X: l1_x2,
                                                             line1Point2Y: l1_y2,
                                                             line2Point1X: l2_x1,
                                                             line2Point1Y: l2_y1,
                                                             line2Point2X: l2_x2,
                                                             line2Point2Y: l2_y2) {
                        return true
                    }
                    
                    checkIndex += 1
                }
                seekIndex += 1
            }
        }
        return false
    }
    
}
