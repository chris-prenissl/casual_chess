//
//  ChessBoard.swift
//  Casual Chess
//
//  Created by Christoph Prenissl on 10.01.21.
//

import Foundation
import SwiftUI

class ChessBoardGame: ObservableObject {
    
    struct historyElement {
        var fromFields = [Coordinate : Piece?]()
        var toFields = [Coordinate : Piece?]()
        var twoSteppedPawnCoordinate : Coordinate? = nil
    }
    
    let rows = 8, columns = 8
    
    @Published var piecesBoard: [[Piece?]] = startingConfiguration
    
    @Published var activePlayer: PieceColor = .white
    var currentChosenPiece: Piece?
    @Published var currentChosenPieceCoordinate: Coordinate?
    
    var isLeftCastleMove = false
    var isRightCastleMove = false
    var isEnPasantMove = false
    var currentTwoSteppedPawnCoordinate: Coordinate?
    var currentTwoSteppedPawnColor: PieceColor?
    @Published var currentMoves = [Coordinate : Bool]()
    
    var history = [historyElement]()
    
    func restart() {
        piecesBoard = startingConfiguration
        activePlayer = .white
        currentChosenPiece = nil
        currentChosenPieceCoordinate = nil
        currentTwoSteppedPawnCoordinate = nil
        currentTwoSteppedPawnColor = nil
        currentMoves = [:]
        history = []
    }
    
    func movePieceTo(x: Int, y: Int) {
        guard let pieceCoordinate = currentChosenPieceCoordinate, let chosenPiece = currentChosenPiece else {
            print("No piece was chosen")
            return
        }
        
        if chosenPiece.type == .pawn {
            let pawnDir = activePlayer == .white ? -1 : 1
            if currentTwoSteppedPawnCoordinate == Coordinate(x: x, y: y - pawnDir) {
                isEnPasantMove = true
            }
        } else {
            isEnPasantMove = false
        }
        
        if chosenPiece.type == .king && !chosenPiece.moved && pieceCoordinate.x - x != 1 {
            isLeftCastleMove = x - pieceCoordinate.x < 1
            isRightCastleMove = x - pieceCoordinate.x > 1
        } else {
            isLeftCastleMove = false
            isRightCastleMove = false
        }
        
        saveMove(rootFile: pieceCoordinate, destFile: Coordinate(x: x, y: y))
        
        piecesBoard[y][x] = chosenPiece
        piecesBoard[pieceCoordinate.y][pieceCoordinate.x] = nil
        
        currentChosenPieceCoordinate = Coordinate(x: x, y: y)
        piecesBoard[y][x]?.moved = true
        
        if isEnPasantMove {
            piecesBoard[currentTwoSteppedPawnCoordinate!.y][currentTwoSteppedPawnCoordinate!.x] = nil
            isEnPasantMove = false
        } else if isRightCastleMove {
            piecesBoard[y][5] = piecesBoard[y][7]
            piecesBoard[y][7] = nil
            isRightCastleMove = false
        } else if isLeftCastleMove {
            piecesBoard[y][3] = piecesBoard[y][0]
            piecesBoard[y][0] = nil
            isLeftCastleMove = false
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
        resetCurrentMoves()
        resetMovesOf(pCoor: coordinate)
        createMovesForPiece(pCoor: coordinate)
        setCurrentMovesOf(pCoor: coordinate)
    }
    
    private func setNextPlayer() {
        activePlayer = activePlayer == .white ? .black : .white
    }
    
    private func unsetChosenPiece() {
        resetMovesOf(pCoor: currentChosenPieceCoordinate!)
        resetCurrentMoves()
        currentChosenPiece = nil
        currentChosenPieceCoordinate = nil
    }
    
    private func saveMove(rootFile: Coordinate, destFile: Coordinate) {
        var moveHistoryElement = historyElement()
        
        moveHistoryElement.twoSteppedPawnCoordinate = currentTwoSteppedPawnCoordinate
        
        moveHistoryElement.fromFields.updateValue(piecesBoard[rootFile.y][rootFile.x], forKey: rootFile)
        moveHistoryElement.toFields.updateValue(piecesBoard[destFile.y][destFile.x], forKey: destFile)
        
        if isEnPasantMove {
            let direction = activePlayer == .white ? 1 : -1
            let enPasant = Coordinate(x: destFile.x, y: destFile.y + direction)
            moveHistoryElement.toFields.updateValue(piecesBoard[enPasant.y][enPasant.x], forKey: enPasant)
        } else if isRightCastleMove {
            moveHistoryElement.fromFields.updateValue(piecesBoard[rootFile.y][7], forKey: Coordinate(x: 7, y: rootFile.y))
            moveHistoryElement.toFields.updateValue(piecesBoard[rootFile.y][5], forKey: Coordinate(x: 5, y: rootFile.y))
        } else if isLeftCastleMove {
            moveHistoryElement.fromFields.updateValue(piecesBoard[rootFile.y][0], forKey: Coordinate(x: 0, y: rootFile.y))
            moveHistoryElement.toFields.updateValue(piecesBoard[rootFile.y][3], forKey: Coordinate(x: 3, y: rootFile.y))
        }
        history.append(moveHistoryElement)
    }
    
    func restoreLastMove() {
        if !history.isEmpty {
            
            let lastHistoryElement = history.popLast()!
            activePlayer = activePlayer == .white ? .black : .white
            resetCurrentMoves()
            currentChosenPiece = nil
            currentChosenPieceCoordinate = nil
            
            if currentTwoSteppedPawnCoordinate != nil {
                currentTwoSteppedPawnColor = activePlayer == .white ? .black : .white
            } else {
                currentTwoSteppedPawnColor = nil
            }
            
            for file in lastHistoryElement.fromFields {
                piecesBoard[file.key.y][file.key.x] = file.value
            }
            for file in lastHistoryElement.toFields {
                piecesBoard[file.key.y][file.key.x] = file.value
            }
        }
    }
    
    private func createMovesForPiece(pCoor: Coordinate) {
        
        switch piecesBoard[pCoor.y][pCoor.x]?.type {
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
            default:
            break
        }
    }
    
    private func resetCurrentMoves() {
        currentMoves = [:]
    }
    
    private func resetMovesOf(pCoor: Coordinate) {
        piecesBoard[pCoor.y][pCoor.x]!.moveList = [:]
        piecesBoard[pCoor.y][pCoor.x]!.possibleAttackMoveList = [:]
    }
    
    private func setCurrentMovesOf(pCoor: Coordinate) {
        currentMoves = piecesBoard[pCoor.y][pCoor.x]!.moveList
    }
    
    private func appendIfCorrect(pCoor: Coordinate, cursor: Coordinate) -> Bool {
        if isCoordinateOutOfBounds(cursor) { return false }
        
        guard let destPiece = piecesBoard[cursor.y][cursor.x] else {
            piecesBoard[pCoor.y][pCoor.x]!.moveList.updateValue(true, forKey: cursor)
            piecesBoard[pCoor.y][pCoor.x]!.possibleAttackMoveList.updateValue(true, forKey: cursor)
            return true
        }
        
        if destPiece.color != piecesBoard[pCoor.y][pCoor.x]!.color  {
            piecesBoard[pCoor.y][pCoor.x]!.moveList.updateValue(true, forKey: cursor)
            piecesBoard[pCoor.y][pCoor.x]!.possibleAttackMoveList.updateValue(true, forKey: cursor)
            return false
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
        
        guard let piece = piecesBoard[pCoor.y][pCoor.x] else {
            print("Error chosing piece")
            return
        }
        
        let direction = piecesBoard[pCoor.y][pCoor.x]!.color == .white ? -1 : 1
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
        _ = appendPawnAttacksIfCorrect(pCoor: pCoor, cursor: cursor)
        
        cursor.x = pCoor.x - 1
        _ = appendPawnAttacksIfCorrect(pCoor: pCoor, cursor: cursor)
    }
    
    private func appendPawnMoveIfCorrect(pCoor: Coordinate, cursor: Coordinate) -> Bool {
        if isCoordinateOutOfBounds(cursor) { return false }
        
        if piecesBoard[cursor.y][cursor.x] == nil {
            piecesBoard[pCoor.y][pCoor.x]!.moveList.updateValue(true, forKey: cursor)
            return true
        }
        return false
    }
    
    private func appendPawnAttacksIfCorrect(pCoor: Coordinate, cursor: Coordinate) -> Bool {
        if isCoordinateOutOfBounds(cursor) { return false }
        
        let piece = piecesBoard[cursor.y][cursor.x]
            
        if piece?.color != piecesBoard[pCoor.y][pCoor.x]!.color {
            piecesBoard[pCoor.y][pCoor.x]!.possibleAttackMoveList.updateValue(true, forKey: cursor)
            
            guard piece != nil else { return true }
            piecesBoard[pCoor.y][pCoor.x]!.moveList.updateValue(true, forKey: cursor)
            
            return true
        }
        return false
    }
}


//King movement
extension ChessBoardGame {
    private func createMovesForKing(pCoor: Coordinate) {
        
        guard piecesBoard[pCoor.y][pCoor.x] != nil else {
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
        
        if piecesBoard[pCoor.y][0]?.moved == false && !piecesBoard[pCoor.y][pCoor.x]!.moved {
            var emptyFiles = true
            for i in stride(from: pCoor.x-1, through: 1, by: -1) {
                if piecesBoard[pCoor.y][i] != nil {
                    emptyFiles = false
                    break
                }
            }
            if emptyFiles {
                _ = appendIfCorrect(pCoor: pCoor, cursor: Coordinate(x: 2, y: pCoor.y))
            }
        }
        if piecesBoard[pCoor.y][7]?.moved == false && !piecesBoard[pCoor.y][pCoor.x]!.moved {
            var emptyFiles = true
            for i in stride(from: pCoor.x+1, through: 6, by: 1) {
                if piecesBoard[pCoor.y][i] != nil {
                    emptyFiles = false
                    break
                }
            }
            if emptyFiles {
                _ = appendIfCorrect(pCoor: pCoor, cursor: Coordinate(x: 6, y: pCoor.y))
            }
        }
        
        if currentChosenPieceCoordinate == pCoor {
            removeKingViolatingPositions()
        }
    }
    
    private func removeKingViolatingPositions() {
    
        for i in 0...(rows-1) {
            for j in 0...(columns-1) {
                guard piecesBoard[i][j] != nil && piecesBoard[i][j]?.color != activePlayer else { continue }
                
                createMovesForPiece(pCoor: Coordinate(x: j, y: i))
                let kingCoor = currentChosenPieceCoordinate!
                let kingMoves = piecesBoard[kingCoor.y][kingCoor.x]!.moveList
                let enemyPiecesMoves = piecesBoard[i][j]!.possibleAttackMoveList
                
                
                for enemyMove in enemyPiecesMoves.keys {
                    if kingMoves[enemyMove] == true {
                        piecesBoard[kingCoor.y][kingCoor.x]!.moveList.updateValue(false, forKey: enemyMove)
                    }
                }
                resetMovesOf(pCoor: Coordinate(x: j, y: i))
            }
        }
    }
}



//Queen movement
extension ChessBoardGame {
    private func createMovesForQueen(pCoor: Coordinate) {
        
        guard piecesBoard[pCoor.y][pCoor.x] != nil else {
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
        
        guard piecesBoard[pCoor.y][pCoor.x] != nil else {
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
        
        guard piecesBoard[pCoor.y][pCoor.x] != nil else {
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
        
        guard piecesBoard[pCoor.y][pCoor.x] != nil else {
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


let startingConfiguration = [[Piece(type: .rook, color: .black), Piece(type: .knight, color: .black), Piece(type: .bishop, color: .black), Piece(type: .queen, color: .black), Piece(type: .king, color: .black), Piece(type: .bishop, color: .black), Piece(type: .knight, color: .black), Piece(type: .rook, color: .black)],
                             [Piece(type: .pawn, color: .black), Piece(type: .pawn, color: .black), Piece(type: .pawn, color: .black), Piece(type: .pawn, color: .black), Piece(type: .pawn, color: .black), Piece(type: .pawn, color: .black), Piece(type: .pawn, color: .black), Piece(type: .pawn, color: .black)],
                             [nil, nil, nil, nil, nil, nil, nil, nil],
                             [nil, nil, nil, nil, nil, nil, nil, nil],
                             [nil, nil, nil, nil, nil, nil, nil, nil],
                             [nil, nil, nil, nil, nil, nil, nil, nil],
                             [Piece(type: .pawn, color: .white), Piece(type: .pawn, color: .white), Piece(type: .pawn, color: .white), Piece(type: .pawn, color: .white), Piece(type: .pawn, color: .white), Piece(type: .pawn, color: .white), Piece(type: .pawn, color: .white), Piece(type: .pawn, color: .white)],
                             [Piece(type: .rook, color: .white), Piece(type: .knight, color: .white), Piece(type: .bishop, color: .white), Piece(type: .queen, color: .white), Piece(type: .king, color: .white), Piece(type: .bishop, color: .white), Piece(type: .knight, color: .white), Piece(type: .rook, color: .white)]]
