//
//  StochasticSplineReducerPathChopperNode.swift
//  PoopMeasure
//
//  Created by Nick Raptis on 12/3/24.
//

import Foundation

class StochasticSplineReducerPathChopperNode {
    
    var links = [Int]()
    var linkCount = 0
    
    func addLink(_ link: Int) {
        while links.count <= linkCount {
            links.append(link)
        }
        links[linkCount] = link
        linkCount += 1
    }
    
    func reset() {
        linkCount = 0
    }
    
}
