//
//  Piece.swift
//  Casual Chess
//
//  Created by Christoph Prenissl on 10.01.21.
//

enum PieceType : String {
    case king, queen, rook, bishop, knight, pawn
}

enum PieceColor {
    case black, white
}

struct Piece {
    var type: PieceType
    var color: PieceColor
    var url: String {
        let colorCode = color == .black ? "b" : "w"
        return type.rawValue + "_" + colorCode
    }
    var moved = false
}

