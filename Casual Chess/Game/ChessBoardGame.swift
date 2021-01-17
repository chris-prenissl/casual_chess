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
    
    @Published var activePlayer: PieceColor = .white
    var currentChosenPiece: Piece?
    @Published var currentChosenPieceCoordinate: Coordinate?
    
    var currentTwoSteppedPawnCoordinate: Coordinate?
    var currentTwoSteppedPawnColor: PieceColor?
    
    let urlString: String = "chess_board"
    
    @Published var piecesBoard: [[Piece?]] = [[Piece(type: .rook, color: .black), Piece(type: .knight, color: .black), Piece(type: .bishop, color: .black), Piece(type: .queen, color: .black), Piece(type: .king, color: .black), Piece(type: .bishop, color: .black), Piece(type: .knight, color: .black), Piece(type: .rook, color: .black)],
                             [Piece(type: .pawn, color: .black), Piece(type: .pawn, color: .black), Piece(type: .pawn, color: .black), Piece(type: .pawn, color: .black), Piece(type: .pawn, color: .black), Piece(type: .pawn, color: .black), Piece(type: .pawn, color: .black), Piece(type: .pawn, color: .black)],
                             [nil, nil, nil, nil, nil, nil, nil, nil],
                             [nil, nil, nil, nil, nil, nil, nil, nil],
                             [nil, nil, nil, nil, nil, nil, nil, nil],
                             [nil, nil, nil, nil, nil, nil, nil, nil],
                             [Piece(type: .pawn, color: .white), Piece(type: .pawn, color: .white), Piece(type: .pawn, color: .white), Piece(type: .pawn, color: .white), Piece(type: .pawn, color: .white), Piece(type: .pawn, color: .white), Piece(type: .pawn, color: .white), Piece(type: .pawn, color: .white)],
                             [Piece(type: .rook, color: .white), Piece(type: .knight, color: .white), Piece(type: .bishop, color: .white), Piece(type: .queen, color: .white), Piece(type: .king, color: .white), Piece(type: .bishop, color: .white), Piece(type: .knight, color: .white), Piece(type: .rook, color: .white)]]
    @Published var currentMoves: [[Bool]] = Array(repeating: Array(repeating: false, count: 8), count: 8)
    var moveList = [Coordinate]()
    
    func movePieceTo(x: Int, y: Int) {
        guard let pieceCoordinate = currentChosenPieceCoordinate, let chosenPiece = currentChosenPiece else {
            print("No piece was chosen")
            return
        }
        
        piecesBoard[y][x] = chosenPiece
        piecesBoard[pieceCoordinate.y][pieceCoordinate.x] = nil
        
        piecesBoard[y][x]?.moved = true
        
        if (chosenPiece.color == .white && y == 0) || (chosenPiece.color == .black && y == rows-1) {
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
        if (isCoordinateOutOfBounds(coordinate)) {
            print("Error occured \(coordinate) is out of bounds")
            return
        }
        
        currentChosenPiece = piecesBoard[coordinate.y][coordinate.x]
        currentChosenPieceCoordinate = coordinate
        createMovesForCurrentPiece()
    }
    
    private func setNextPlayer() {
        unsetChosenPiece()
        activePlayer = activePlayer == .white ? .black : .white
    }
    
    private func unsetChosenPiece() {
        currentChosenPiece = nil
        currentChosenPieceCoordinate = nil
        resetMoves()
    }
    
    private func createMovesForCurrentPiece() {
        
        resetMoves()
        
        guard let pieceX = currentChosenPieceCoordinate?.x, let pieceY = currentChosenPieceCoordinate?.y else { return }
        
        switch currentChosenPiece?.type {
        case .pawn:
            createMovesForPawn(x: pieceX, y: pieceY)
        case .king:
            createMovesForKing(x: pieceX, y: pieceY)
        case .queen:
            createMovesForQueen(x: pieceX, y: pieceY)
        default:
            break
        }
        
        setMovesFromMoveList()
    }
    
    private func setMovesFromMoveList() {
        for move in moveList {
            currentMoves[move.y][move.x] = true
        }
    }
    
    private func resetMoves() {
        currentMoves = Array(repeating: Array(repeating: false, count: columns), count: rows)
        moveList = []
    }
    
    private func appendIfNotOutOfBounds(coordinate: Coordinate) {
        
        if !isCoordinateOutOfBounds(coordinate) {
            moveList.append(coordinate)
        }
    }
    
    private func appendIfNotOutOfBoundsAndNotSameColor(coordinate: Coordinate) {
        if !isCoordinateOutOfBounds(coordinate) {
            if piecesBoard[coordinate.y][coordinate.x]?.color != currentChosenPiece?.color {
                moveList.append(coordinate)
            }
        }
    }
    
    private func isCoordinateOutOfBounds(_ coordinate: Coordinate) -> Bool {
        return coordinate.x < 0 || coordinate.x > columns-1 || coordinate.y < 0 || coordinate.y > rows-1
    }
    
}



//Pawn Moves
extension ChessBoardGame {
    
    private func createMovesForPawn(x: Int, y: Int) {
        
        guard let piece = currentChosenPiece else {
            print("Error chosing piece")
            return
        }
        
        let direction = activePlayer == .white ? -1 : 1
        var cursor = Coordinate(x: x, y: y)
        

        cursor.x = x - 1
        if currentTwoSteppedPawnCoordinate == cursor && currentTwoSteppedPawnColor != piece.color {
            cursor.y = y + direction
            appendIfNotOutOfBounds(coordinate: cursor)
        }
        
        cursor.x = x + 1
        cursor.y = y
        if currentTwoSteppedPawnCoordinate == cursor && currentTwoSteppedPawnColor != piece.color {
            cursor.y = y + direction
            appendIfNotOutOfBounds(coordinate: cursor)
        }

        cursor = Coordinate(x: x, y: y + direction)
        if !isCoordinateOutOfBounds(cursor) {
            if piecesBoard[cursor.y][cursor.x] == nil {
                moveList.append(cursor)
            }
            cursor.y += direction
            if !piece.moved && piecesBoard[cursor.y][cursor.x] == nil {
                moveList.append(cursor)
            }
        }
        
        cursor.x = x + 1
        cursor.y = y + direction
        if !isCoordinateOutOfBounds(cursor) {
            if piecesBoard[cursor.y][cursor.x] != nil && piecesBoard[cursor.y][cursor.x]?.color != piece.color {
                moveList.append(cursor)
            }
        }
        
        cursor.x = x - 1
        if !isCoordinateOutOfBounds(cursor) {
            if piecesBoard[cursor.y][cursor.x] != nil && piecesBoard[cursor.y][cursor.x]?.color != piece.color {
                moveList.append(cursor)
            }
        }
    }
}


//King movement
extension ChessBoardGame {
    private func createMovesForKing(x: Int, y: Int) {
        
        guard currentChosenPiece != nil else {
            print("Error chosing piece")
            return
        }
        
        var cursor = Coordinate(x: x, y: y)
        
        cursor.x = x - 1
        appendIfNotOutOfBoundsAndNotSameColor(coordinate: cursor)
        cursor.y = y - 1
        appendIfNotOutOfBoundsAndNotSameColor(coordinate: cursor)
        cursor.y = y + 1
        appendIfNotOutOfBoundsAndNotSameColor(coordinate: cursor)
        
        cursor.x = x
        appendIfNotOutOfBoundsAndNotSameColor(coordinate: cursor)
        cursor.y = y - 1
        appendIfNotOutOfBoundsAndNotSameColor(coordinate: cursor)
        
        cursor.x = x + 1
        appendIfNotOutOfBoundsAndNotSameColor(coordinate: cursor)
        cursor.y = y
        appendIfNotOutOfBoundsAndNotSameColor(coordinate: cursor)
        cursor.y = y + 1
        appendIfNotOutOfBoundsAndNotSameColor(coordinate: cursor)
    }
}



//Queen movement
extension ChessBoardGame {
    private func createMovesForQueen(x: Int, y: Int) {
        
        guard currentChosenPiece != nil else {
            print("Error chosing piece")
            return
        }
        
        var cursor = Coordinate(x: x, y: y)
        
        //TODO
    }
}
