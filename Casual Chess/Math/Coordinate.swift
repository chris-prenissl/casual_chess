//
//  Coordinates.swift
//  Casual Chess
//
//  Created by Christoph Prenissl on 16.01.21.
//

struct Coordinate : Equatable, Hashable {
    var x: Int
    var y: Int
    
    
    mutating func add(otherCoordinate: Coordinate) {
        x += otherCoordinate.x
        y += otherCoordinate.y
    }
    
    mutating func scalarMult(lambda: Int) {
        x *= lambda
        y *= lambda
    }
    
    
    static func == (lhs: Coordinate, rhs: Coordinate) -> Bool {
        return lhs.x == rhs.x && lhs.y == rhs.y
    }
    
    func hash(into hasher: inout Hasher) {
            hasher.combine(x)
            hasher.combine(y)
        }
}
