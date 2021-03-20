//
//  ChessAI.swift
//  Casual Chess
//
//  Created by Christoph Prenissl on 08.02.21.
//

import Foundation

class ChessAI {
    let color: PieceColor
    var board: [[Piece?]] = [[]]
    let width: Int
    let height: Int
    
    var piecesCoordinates: [Coordinate] = []
    var moveList: [Coordinate] = []
    
    
    init(color: PieceColor, width: Int, height: Int) {
        self.color = color
        self.width = width
        self.height = height
    }
    
    public func setBoard(board: [[Piece?]]) {
        self.board = board
    }
    
    public func choosePiece() -> Coordinate {
        for j in 0..<width {
            for i in 0..<height {
                guard let piece = board[i][j], piece.color == color else {
                    continue
                }
                if !piece.moveList.isEmpty {
                    piecesCoordinates.append(Coordinate(x: j, y: i))
                }
            }
        }
        return piecesCoordinates.randomElement()!
    }
    
    public func createMove(pCoor: Coordinate) -> Coordinate {
        return (board[pCoor.y][pCoor.x]?.moveList.randomElement()!.key)!
    }
}
