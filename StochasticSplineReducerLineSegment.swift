//
//  StochasticSplineReducerLineSegment.swift
//  Yo Mamma Be Ugly
//
//  Created by Nick Raptis on 11/30/24.
//

import Foundation
import MathKit

class StochasticSplineReducerSegment {
    
    var isFlagged = false
    
    var x1: Float = 0.0
    var y1: Float = 0.0
    var x2: Float = 0.0
    var y2: Float = 0.0
    
    var directionX = Float(0.0)
    var directionY = Float(-1.0)
    
    var lengthSquared = Float(1.0)
    var length = Float(1.0)
    
    func precompute() {
        directionX = x2 - x1
        directionY = y2 - y1
        lengthSquared = directionX * directionX + directionY * directionY
        if lengthSquared > Math.epsilon {
            length = sqrtf(lengthSquared)
            directionX /= length
            directionY /= length
        } else {
            directionX = Float(0.0)
            directionY = Float(-1.0)
            length = 0.0
        }
    }
    
    func distanceSquaredToClosestPoint(_ x: Float, _ y: Float) -> Float {
        let factor1X = x - x1
        let factor1Y = y - y1
        if lengthSquared > Math.epsilon {
            let scalar = directionX * factor1X + directionY * factor1Y
            if scalar <= 0.0 {
                let diffX = x1 - x
                let diffY = y1 - y
                let result = diffX * diffX + diffY * diffY
                return result
            } else if scalar >= length {
                let diffX = x2 - x
                let diffY = y2 - y
                let result = diffX * diffX + diffY * diffY
                return result
            } else {
                let closestX = x1 + directionX * scalar
                let closestY = y1 + directionY * scalar
                let diffX = closestX - x
                let diffY = closestY - y
                let result = diffX * diffX + diffY * diffY
                return result
            }
        }
        return 0.0
    }
}
