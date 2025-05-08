//
//  StochasticSplineReducerExploredPool.swift
//  PoopMeasure
//
//  Created by Nick Raptis on 12/3/24.
//

import Foundation

class StochasticSplineReducerExploredPool {
    
    func clear() {
        root.clear()
    }
    
    func contains(chopper: StochasticSplineReducerPathChopper) -> Bool {
        var node = root
        var listIndex = 0
        while listIndex < chopper.pathCount {
            let value = chopper.path[listIndex]
            if let nextNode = node.descendants[value] {
                node = nextNode
                listIndex += 1
            } else {
                return false
            }
        }
        
        return node.isLeaf
    }
    
    func contains(list: [Int]) -> Bool {
        var node = root
        var listIndex = 0
        while listIndex < list.count {
            let value = list[listIndex]
            if let nextNode = node.descendants[value] {
                node = nextNode
                listIndex += 1
            } else {
                return false
            }
        }
        
        return node.isLeaf
    }
    
    func ingest(list: [Int]) {
        var node = root
        var listIndex = 0
        while listIndex < list.count {
            let value = list[listIndex]
            if let nextNode = node.descendants[value] {
                node = nextNode
                listIndex += 1
            } else {
                break
            }
        }
        
        while listIndex < list.count {
            let value = list[listIndex]
            let newNode = StochasticSplineReducerExploredNode()
            newNode.index = value
            node.descendants[value] = newNode
            node = newNode
            listIndex += 1
        }
        
        node.isLeaf = true
    }
    
    func ingest(chopper: StochasticSplineReducerPathChopper) {
        var node = root
        var listIndex = 0
        while listIndex < chopper.pathCount {
            let value = chopper.path[listIndex]
            if let nextNode = node.descendants[value] {
                node = nextNode
                listIndex += 1
            } else {
                break
            }
        }
        
        while listIndex < chopper.pathCount {
            let value = chopper.path[listIndex]
            let newNode = StochasticSplineReducerExploredNode()
            newNode.index = value
            node.descendants[value] = newNode
            node = newNode
            listIndex += 1
        }
        
        node.isLeaf = true
    }
    
    let root = StochasticSplineReducerExploredNode()
    
}
