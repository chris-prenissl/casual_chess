//
//  ChessBoard.swift
//  Casual Chess
//
//  Created by Christoph Prenissl on 10.01.21.
//

import Foundation
import SwiftUI

class ChessBoardGame: ObservableObject {
    let rows = 8, columns = 8
    
    @Published var piecesBoard: [[Piece?]] = [[Piece(type: .rook, color: .black), Piece(type: .knight, color: .black), Piece(type: .bishop, color: .black), Piece(type: .queen, color: .black), Piece(type: .king, color: .black), Piece(type: .bishop, color: .black), Piece(type: .knight, color: .black), Piece(type: .rook, color: .black)],
                             [Piece(type: .pawn, color: .black), Piece(type: .pawn, color: .black), Piece(type: .pawn, color: .black), Piece(type: .pawn, color: .black), Piece(type: .pawn, color: .black), Piece(type: .pawn, color: .black), Piece(type: .pawn, color: .black), Piece(type: .pawn, color: .black)],
                             [nil, nil, nil, nil, nil, nil, nil, nil],
                             [nil, nil, nil, nil, nil, nil, nil, nil],
                             [nil, nil, nil, nil, nil, nil, nil, nil],
                             [nil, nil, nil, nil, nil, nil, nil, nil],
                             [Piece(type: .pawn, color: .white), Piece(type: .pawn, color: .white), Piece(type: .pawn, color: .white), Piece(type: .pawn, color: .white), Piece(type: .pawn, color: .white), Piece(type: .pawn, color: .white), Piece(type: .pawn, color: .white), Piece(type: .pawn, color: .white)],
                             [Piece(type: .rook, color: .white), Piece(type: .knight, color: .white), Piece(type: .bishop, color: .white), Piece(type: .queen, color: .white), Piece(type: .king, color: .white), Piece(type: .bishop, color: .white), Piece(type: .knight, color: .white), Piece(type: .rook, color: .white)]]
    
    @Published var activePlayer: PieceColor = .white
    var currentChosenPiece: Piece?
    @Published var currentChosenPieceCoordinate: Coordinate?
    
    var currentTwoSteppedPawnCoordinate: Coordinate?
    var currentTwoSteppedPawnColor: PieceColor?
    @Published var currentMoves = [Coordinate : Bool]()
    
    func movePieceTo(x: Int, y: Int) {
        guard let pieceCoordinate = currentChosenPieceCoordinate, let chosenPiece = currentChosenPiece else {
            print("No piece was chosen")
            return
        }
        
        piecesBoard[y][x] = chosenPiece
        piecesBoard[pieceCoordinate.y][pieceCoordinate.x] = nil
        
        piecesBoard[y][x]?.moved = true
        
        if chosenPiece.type == .pawn {
            let pawnDir = activePlayer == .white ? -1 : 1
            if currentTwoSteppedPawnCoordinate == Coordinate(x: x, y: y - pawnDir) {
                piecesBoard[currentTwoSteppedPawnCoordinate!.y][currentTwoSteppedPawnCoordinate!.x] = nil
            }
        }
        
        if ((chosenPiece.color == .white && y == 0) || (chosenPiece.color == .black && y == rows-1)) && chosenPiece.type == .pawn {
            piecesBoard[y][x]?.type = .queen
        }
        
        if chosenPiece.type == .pawn && abs(y - pieceCoordinate.y) > 1 {
            currentTwoSteppedPawnCoordinate = Coordinate(x: x, y: y)
            currentTwoSteppedPawnColor = chosenPiece.color
        } else {
            currentTwoSteppedPawnCoordinate = nil
            currentTwoSteppedPawnColor = nil
        }
        
        unsetChosenPiece()
        setNextPlayer()
    }
    
    func setCurrentChosenPiece(coordinate: Coordinate) {
        guard let piece = piecesBoard[coordinate.y][coordinate.x] else {
            print("Error occured \(coordinate) is out of bounds")
            return
        }
        
        currentChosenPiece = piece
        currentChosenPieceCoordinate = coordinate
        createMovesForPiece(pCoor: coordinate)
    }
    
    private func setNextPlayer() {
        activePlayer = activePlayer == .white ? .black : .white
    }
    
    private func unsetChosenPiece() {
        currentChosenPiece = nil
        currentChosenPieceCoordinate = nil
        resetCurrentMoves()
    }
    
    private func createMovesForPiece(pCoor: Coordinate) {
        
        resetCurrentMoves()
        resetMovesOf(pCoor: pCoor)
        
        switch piecesBoard[pCoor.y][pCoor.x]!.type {
            case .pawn:
                createMovesForPawn(pCoor: pCoor)
                break
            case .king:
                createMovesForKing(pCoor: pCoor)
                break
            case .queen:
                createMovesForQueen(pCoor: pCoor)
                break
            case .rook:
                createMovesForRook(pCoor: pCoor)
                break
            case .bishop:
                createMovesForBishop(pCoor: pCoor)
                break
            case .knight:
                createMovesForKnight(pCoor: pCoor)
                break
        }
        setCurrentMovesOf(pCoor: pCoor)
    }
    
    private func resetCurrentMoves() {
        currentMoves = [:]
    }
    
    private func resetMovesOf(pCoor: Coordinate) {
        piecesBoard[pCoor.y][pCoor.x]!.moveList = [:]
    }
    
    private func setCurrentMovesOf(pCoor: Coordinate) {
        currentMoves = piecesBoard[pCoor.y][pCoor.x]!.moveList
    }
    
    private func appendIfCorrect(pCoor: Coordinate, cursor: Coordinate) -> Bool {
        if isCoordinateOutOfBounds(cursor) { return false }
        
        if piecesBoard[cursor.y][cursor.x]?.color != piecesBoard[pCoor.y][pCoor.x]!.color  {
            piecesBoard[pCoor.y][pCoor.x]!.moveList.updateValue(true, forKey: cursor)
            return true
        }
        return false
    }
    
    private func isCoordinateOutOfBounds(_ coordinate: Coordinate) -> Bool {
        return coordinate.x < 0 || coordinate.x > columns-1 || coordinate.y < 0 || coordinate.y > rows-1
    }
}



//Pawn Moves
extension ChessBoardGame {
    private func createMovesForPawn(pCoor: Coordinate) {
        
        guard let piece = currentChosenPiece else {
            print("Error chosing piece")
            return
        }
        
        let direction = activePlayer == .white ? -1 : 1
        var cursor = Coordinate(x: pCoor.x, y: pCoor.y)
        

        cursor.x = pCoor.x - 1
        if currentTwoSteppedPawnCoordinate == cursor && currentTwoSteppedPawnColor != piece.color {
            cursor.y = pCoor.y + direction
            _ = appendPawnMoveIfCorrect(pCoor: pCoor, cursor: cursor)
        }
        
        cursor.x = pCoor.x + 1
        cursor.y = pCoor.y
        if currentTwoSteppedPawnCoordinate == cursor && currentTwoSteppedPawnColor != piece.color {
            cursor.y = pCoor.y + direction
            _ = appendPawnMoveIfCorrect(pCoor: pCoor, cursor: cursor)
        }

        cursor = Coordinate(x: pCoor.x, y: pCoor.y + direction)
        _ = appendPawnMoveIfCorrect(pCoor: pCoor, cursor: cursor)
        cursor.y += direction
        if !piece.moved {
            _ = appendPawnMoveIfCorrect(pCoor: pCoor, cursor: cursor)
        }
        
        cursor.x = pCoor.x + 1
        cursor.y = pCoor.y + direction
        _ = appendPawnAttackIfCorrect(pCoor: pCoor, cursor: cursor)
        
        cursor.x = pCoor.x - 1
        _ = appendPawnAttackIfCorrect(pCoor: pCoor, cursor: cursor)
    }
    
    private func appendPawnMoveIfCorrect(pCoor: Coordinate, cursor: Coordinate) -> Bool {
        if isCoordinateOutOfBounds(cursor) { return false }
        
        if piecesBoard[cursor.y][cursor.x] == nil {
            piecesBoard[pCoor.y][pCoor.x]!.moveList.updateValue(true, forKey: cursor)
            return true
        }
        return false
    }
    
    private func appendPawnAttackIfCorrect(pCoor: Coordinate, cursor: Coordinate) -> Bool {
        if isCoordinateOutOfBounds(cursor) { return false }
        
        guard let piece = piecesBoard[cursor.y][cursor.x] else { return false }
            
        if piece.color != piecesBoard[pCoor.y][pCoor.x]!.color {
            piecesBoard[pCoor.y][pCoor.x]!.moveList.updateValue(true, forKey: cursor)
            return true
        }
        return false
    }
}


//King movement
extension ChessBoardGame {
    private func createMovesForKing(pCoor: Coordinate) {
        
        guard currentChosenPiece != nil else {
            print("Error chosing piece")
            return
        }
        
        var cursor = Coordinate(x: pCoor.x, y: pCoor.y)
        
        cursor.x = pCoor.x - 1
        _ = appendIfCorrect(pCoor: pCoor, cursor: cursor)
        cursor.y = pCoor.y - 1
        _ = appendIfCorrect(pCoor: pCoor, cursor: cursor)
        cursor.y = pCoor.y + 1
        _ = appendIfCorrect(pCoor: pCoor, cursor: cursor)
        
        cursor.x = pCoor.x
        _ = appendIfCorrect(pCoor: pCoor, cursor: cursor)
        cursor.y = pCoor.y - 1
        _ = appendIfCorrect(pCoor: pCoor, cursor: cursor)
        
        cursor.x = pCoor.x + 1
        _ = appendIfCorrect(pCoor: pCoor, cursor: cursor)
        cursor.y = pCoor.y
        _ = appendIfCorrect(pCoor: pCoor, cursor: cursor)
        cursor.y = pCoor.y + 1
        _ = appendIfCorrect(pCoor: pCoor, cursor: cursor)
    }
    
    private func removeViolatingPositions() {
        //save chosen piece and movelist
        let player = activePlayer
        let chosenPiece = currentChosenPiece
        let chosenPieceCoordinate = currentChosenPieceCoordinate
        let moves = currentMoves
        
        for i in 0...rows {
            for j in 0...columns {
                guard let piece = piecesBoard[i][j] else { continue }
                
                if piece.color != player {
                    
                }
            }
        }
    }
}



//Queen movement
extension ChessBoardGame {
    private func createMovesForQueen(pCoor: Coordinate) {
        
        guard currentChosenPiece != nil else {
            print("Error chosing piece")
            return
        }
        
        createMovesForBishop(pCoor: pCoor)
        createMovesForRook(pCoor: pCoor)
    }
}


//Rook movement
extension ChessBoardGame {
    private func createMovesForRook(pCoor: Coordinate) {
        
        guard currentChosenPiece != nil else {
            print("Error chosing piece")
            return
        }
        
        var cursor = Coordinate(x: pCoor.x, y: pCoor.y)
        
        for i in stride(from: pCoor.x+1, through: columns-1, by: 1) {
            cursor.x = i
            
            if !appendIfCorrect(pCoor: pCoor, cursor: cursor) { break }
        }
        
        for i in stride(from: pCoor.x-1, through: 0, by: -1) {
            cursor.x = i
            
            if !appendIfCorrect(pCoor: pCoor, cursor: cursor) { break }
        }
        
        cursor.x = pCoor.x
        for i in stride(from: pCoor.y+1, through: rows-1, by: 1) {
            cursor.y = i
            
            if !appendIfCorrect(pCoor: pCoor, cursor: cursor) { break }
        }
        
        for i in stride(from: pCoor.y-1, through: 0, by: -1) {
            cursor.y = i
            
            if !appendIfCorrect(pCoor: pCoor, cursor: cursor) { break }
        }
    }
}
    
    
//Bishop movement
extension ChessBoardGame {
    private func createMovesForBishop(pCoor: Coordinate) {
        
        guard currentChosenPiece != nil else {
            print("Error chosing piece")
            return
        }
        
        let distRightX = columns-1 - pCoor.x
        let distDownY = rows-1 - pCoor.y
        
        var cursor = Coordinate(x: pCoor.x, y: pCoor.y)
        let smallestDistLeftUp = pCoor.x < pCoor.y ? pCoor.x : pCoor.y
        let smallestDistLeftDown = pCoor.x < distDownY ? pCoor.x : distDownY
        let smallestDistRightUp = distRightX < pCoor.y ? distRightX : pCoor.y
        let smallestDistRightDown = distRightX < distDownY ? distRightX : distDownY
        
        for i in stride(from: 1, through: smallestDistRightDown, by: 1) {
            cursor.x = pCoor.x + i
            cursor.y = pCoor.y + i
            
            if !appendIfCorrect(pCoor: pCoor, cursor: cursor) { break }
        }
        
        for i in stride(from: 1, through: smallestDistRightUp, by: 1) {
            cursor.x = pCoor.x + i
            cursor.y = pCoor.y - i
            
            if !appendIfCorrect(pCoor: pCoor, cursor: cursor) { break }
        }
        
        for i in stride(from: 1, through: smallestDistLeftDown, by: 1) {
            cursor.x = pCoor.x - i
            cursor.y = pCoor.y + i
            
            if !appendIfCorrect(pCoor: pCoor, cursor: cursor) { break }
        }
        
        for i in stride(from: 1, through: smallestDistLeftUp, by: 1) {
            cursor.x = pCoor.x - i
            cursor.y = pCoor.y - i
            
            if !appendIfCorrect(pCoor: pCoor, cursor: cursor) { break }
        }
    }
}


//Knight movement
extension ChessBoardGame {
    private func createMovesForKnight(pCoor: Coordinate) {
        
        guard currentChosenPiece != nil else {
            print("Error chosing piece")
            return
        }
        var cursor = Coordinate(x: pCoor.x, y: pCoor.y)
        
        cursor.x = pCoor.x - 1
        cursor.y = pCoor.y - 2
        _ = !appendIfCorrect(pCoor: pCoor, cursor: cursor)
        
        cursor.x = pCoor.x + 1
        _ = !appendIfCorrect(pCoor: pCoor, cursor: cursor)
        
        cursor.x = pCoor.x + 2
        cursor.y = pCoor.y - 1
        _ = !appendIfCorrect(pCoor: pCoor, cursor: cursor)
        
        cursor.y = pCoor.y + 1
        _ = !appendIfCorrect(pCoor: pCoor, cursor: cursor)
        
        cursor.x = pCoor.x + 1
        cursor.y = pCoor.y + 2
        _ = !appendIfCorrect(pCoor: pCoor, cursor: cursor)
        
        cursor.x = pCoor.x - 1
        _ = !appendIfCorrect(pCoor: pCoor, cursor: cursor)
        
        cursor.x = pCoor.x - 2
        cursor.y = pCoor.y + 1
        _ = !appendIfCorrect(pCoor: pCoor, cursor: cursor)
        
        cursor.y = pCoor.y - 1
        _ = !appendIfCorrect(pCoor: pCoor, cursor: cursor)
    }
}

