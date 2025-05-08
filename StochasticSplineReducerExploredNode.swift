//
//  StochasticSplineReducerExploredNode.swift
//  PoopMeasure
//
//  Created by Nick Raptis on 12/3/24.
//

import Foundation

class StochasticSplineReducerExploredNode {
    
    var index = -1
    
    var descendants = [Int: StochasticSplineReducerExploredNode]()
    var isLeaf = false
    
    func clear() {
        for (_, node) in descendants {
            node.clear()
        }
        descendants.removeAll()
    }
}
