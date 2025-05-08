//
//  StochasticSplineReducer+SampleB.swift
//  Yo Mamma Be Ugly
//
//  Created by Nick Raptis on 12/2/24.
//

import Foundation
import MathKit

extension StochasticSplineReducer {
    
    // [S.R. Czech] 12-3-2024: This function works as intended.
    func addPointTestPointsB(x: Float, y: Float) {
        if testPointCountB >= testPointCapacityB {
            reserveCapacityTestPointsB(minimumCapacity: testPointCountB + (testPointCountB >> 1) + 1)
        }
        testPointsXB[testPointCountB] = x
        testPointsYB[testPointCountB] = y
        testPointCountB += 1
    }
    
    // [S.R. Czech] 12-3-2024: This function works as intended.
    private func reserveCapacityTestPointsB(minimumCapacity: Int) {
        if minimumCapacity > testPointCapacityB {
            testPointsXB.reserveCapacity(minimumCapacity)
            testPointsYB.reserveCapacity(minimumCapacity)
            while testPointsXB.count < minimumCapacity {
                testPointsXB.append(0.0)
            }
            while testPointsYB.count < minimumCapacity {
                testPointsYB.append(0.0)
            }
            testPointCapacityB = minimumCapacity
        }
    }
    
    // [S.R. Czech] 12-3-2024: This function works as intended.
    func getMaximumDistanceFromTestPointsToSegmentsB(isError: inout Bool) -> Float {
        
        if testPointCountB <= 2 {
            isError = true
            return Float.nan
        }
        
        if testSegmentCountB <= 2 {
            isError = true
            return Float.nan
        }
        
        var result = Float(0.0)
        var pointIndexB = 1
        while pointIndexB < testPointCountB {
            let x = testPointsXB[pointIndexB]
            let y = testPointsYB[pointIndexB]
            var minDistanceSquared = Float(100_000_000.0)
            for segmentIndex in 0..<testSegmentCountB {
                let segment = testSegmentsB[segmentIndex]
                let distanceSquared = segment.distanceSquaredToClosestPoint(x, y)
                if distanceSquared < minDistanceSquared {
                    minDistanceSquared = distanceSquared
                }
            }
            if minDistanceSquared > result {
                result = minDistanceSquared
            }
            pointIndexB += 1
        }
        
        isError = false
        return result
    }
    
    // [S.R. Czech] 12-3-2024: This function works as intended.
    func addTestSegmentB(_ segment: StochasticSplineReducerSegment) {
        while testSegmentsB.count <= testSegmentCountB {
            testSegmentsB.append(segment)
        }
        testSegmentsB[testSegmentCountB] = segment
        testSegmentCountB += 1
    }
    
    // [S.R. Czech] 12-3-2024: TODO: This is not verified and not used currently.
    func isTestPointsComplexB() -> Bool {
        
        if testPointCountB > 3 {
            
            var seekIndex = 0
            let seekCeiling = (testPointCountB - 2)
            let checkCeiling = (testPointCountB - 1)
            
            while seekIndex < seekCeiling {
                
                // we check if
                // seekIndex, seekIndex + 1
                // collide with
                // seekIndex + 2...end-1
                // seekIndex + 3...end
                
                let l1_x1 = testPointsXB[seekIndex]
                let l1_y1 = testPointsYB[seekIndex]
                let l1_x2 = testPointsXB[seekIndex + 1]
                let l1_y2 = testPointsYB[seekIndex + 1]
                var checkIndex = seekIndex + 2
                while checkIndex < checkCeiling {
                    let l2_x1 = testPointsXB[checkIndex]
                    let l2_y1 = testPointsYB[checkIndex]
                    let l2_x2 = testPointsXB[checkIndex + 1]
                    let l2_y2 = testPointsYB[checkIndex + 1]
                    if MathKit.Math.lineSegmentIntersectsLineSegment(line1Point1X: l1_x1,
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
