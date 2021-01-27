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
    var history = [historyElement]()
    
    //player
    @Published var activePlayer: PieceColor = .white
    @Published var currentChosenPieceCoordinate: Coordinate?
    @Published var currentMoves = [Coordinate : Bool]()
    
    //game states
    @Published var kingHasToMove = false
    @Published var checkMate = false
    @Published var draw = false
    
    //move type
    var isLeftCastleMove = false
    var isRightCastleMove = false
    var isEnPasantMove = false
    var currentTwoSteppedPawnCoordinate: Coordinate?
    
        
    init() {
        preparePlayPhase()
    }
    
    func restart() {
        piecesBoard = startingConfiguration
        history = []
        activePlayer = .white
        currentChosenPieceCoordinate = nil
        currentMoves = [:]
        kingHasToMove = false
        checkMate = false
        draw = false
        isLeftCastleMove = false
        isRightCastleMove = false
        isEnPasantMove = false
        currentTwoSteppedPawnCoordinate = nil
        
        preparePlayPhase()
    }
    
    private func preparePlayPhase() {
        if createMovesForPlayer(isActive: true) {
            check()
        } else {
            draw = true
        }
    }
    
    private func createMovesForPlayer(isActive: Bool) -> Bool {
        var count = 0
        for i in 0...(rows-1) {
            for j in 0...(columns-1) {
                guard let piece = piecesBoard[i][j] else { continue }
                guard piece.color == activePlayer else { continue }
                
                createMovesForPiece(pCoor: Coordinate(x: j, y: i), isAttacking: isActive)
                
                count += piecesBoard[i][j]!.moveList.count
            }
        }
        return count > 0
    }
    
    private func check() {
        kingHasToMove = false
        guard let kCoor = getKingCoor() else {
            print("No king found")
            return
        }
        if isKingViolated(kCoor: kCoor) {
            currentChosenPieceCoordinate = kCoor
            createMovesForKing(pCoor: kCoor)
            removeKingViolatingMoves(pCoor: kCoor)
            currentChosenPieceCoordinate = kCoor
            currentMoves = getMovesOf(coordinate: kCoor)
            kingHasToMove = true
            var kingCannotMove = true
            for move in currentMoves {
                if move.value { kingCannotMove = false}
            }
            if kingCannotMove {
                checkMate = true
            }
        }
    }
    
    private func getMovesOf(coordinate: Coordinate) -> [Coordinate : Bool] {
        guard let piece = piecesBoard[coordinate.y][coordinate.x] else { return [:] }
        return piece.moveList
    }
    
    func tryToMovePieceTo(x: Int, y: Int) {
        
        guard let pieceCoordinate = currentChosenPieceCoordinate else {
            print("No piece was chosen")
            return
        }
        
        let chosenPiece = getPiece(at: pieceCoordinate)!
        let destination = Coordinate(x: x, y: y)
        setState(chosenPiece: chosenPiece, pieceCoordinate: pieceCoordinate, destination: destination)
        piecesBoard[pieceCoordinate.y][pieceCoordinate.x]!.moved = true
        saveMove(rootFile: pieceCoordinate, destFile: destination)
        move()
        
        //prepare for next player
        setNextPlayer()
        preparePlayPhase()
    }
    
    func setCurrentChosenPiece(coordinate: Coordinate) {
        currentChosenPieceCoordinate = coordinate
        currentMoves = piecesBoard[coordinate.y][coordinate.x]!.moveList
    }
    
    private func setState(chosenPiece: Piece, pieceCoordinate: Coordinate, destination: Coordinate) {
        isEnPasantMove = isEnPasantMove(chosenPiece: chosenPiece, coordinate: destination)
        isLeftCastleMove = isCastleMoveLeft(chosenPieceCoordinate: pieceCoordinate, destination: destination)
        isRightCastleMove = isCastleMoveRight(chosenPieceCoordinate: pieceCoordinate, destination: destination)
        currentTwoSteppedPawnCoordinate = twoSteppedPawnMove(from: pieceCoordinate, destination: destination)
    }
    
    private func move() {
        guard let lastHistoryElement = history.last else {
            print("No element in history")
            return
        }
        var from = lastHistoryElement.fromFields
        var to = lastHistoryElement.toFields
        
        while !from.isEmpty {
            let fromField = from.popFirst()!
            piecesBoard[fromField.key.y][fromField.key.x] = nil
            let toField = to.popFirst()!
            piecesBoard[toField.key.y][toField.key.x] = fromField.value
        }
    }
    
    private func twoSteppedPawnMove(from: Coordinate, destination: Coordinate) -> Coordinate? {
        if piecesBoard[from.y][from.x]?.type == .pawn && abs(destination.y - from.y) == 2 {
            return destination
        }
        return nil
    }
    
    private func isCastleMoveLeft(chosenPieceCoordinate: Coordinate, destination: Coordinate) -> Bool {
        guard let piece = piecesBoard[chosenPieceCoordinate.y][chosenPieceCoordinate.x] else {
            print("Error chosing piece")
            return false
        }
        if piece.type == .king && !piece.moved && chosenPieceCoordinate.x - destination.x == 2 {
            guard let possibleRook = piecesBoard[destination.y][0] else { return false }
            return possibleRook.type == .rook && possibleRook.color == activePlayer && !possibleRook.moved
        }
        return false
    }
    
    private func isCastleMoveRight(chosenPieceCoordinate: Coordinate, destination: Coordinate) -> Bool {
        guard let piece = piecesBoard[chosenPieceCoordinate.y][chosenPieceCoordinate.x] else {
            print("Error chosing piece")
            return false
        }
        if piece.type == .king && !piece.moved && destination.x - chosenPieceCoordinate.x == 2 {
            guard let possibleRook = piecesBoard[destination.y][columns-1] else { return false }
            return possibleRook.type == .rook && possibleRook.color == activePlayer && !possibleRook.moved
        }
        return false
    }
    
    private func isEnPasantMove(chosenPiece: Piece, coordinate: Coordinate) -> Bool {
        if chosenPiece.type == .pawn {
            let enemyPawnDir = activePlayer == .white ? 1 : -1
            if currentTwoSteppedPawnCoordinate == Coordinate(x: coordinate.x, y: coordinate.y + enemyPawnDir) {
                return true
            }
        }
        return false
    }
    
    private func setNextPlayer() {
        activePlayer = activePlayer == .white ? .black : .white
    }
    
    private func saveMove(rootFile: Coordinate, destFile: Coordinate) {
        var moveHistoryElement = historyElement()
        
        moveHistoryElement.twoSteppedPawnCoordinate = currentTwoSteppedPawnCoordinate
        
        moveHistoryElement.fromFields.updateValue(piecesBoard[rootFile.y][rootFile.x], forKey: rootFile)
        moveHistoryElement.toFields.updateValue(piecesBoard[destFile.y][destFile.x], forKey: destFile)
        
        if isEnPasantMove {
            let direction = activePlayer == .white ? 1 : -1
            let enPasantFrom = Coordinate(x: destFile.x, y: destFile.y - direction)
            let enPasantDir = Coordinate(x: destFile.x, y: destFile.y + direction)
            moveHistoryElement.fromFields.updateValue(piecesBoard[enPasantFrom.y][enPasantFrom.x], forKey: enPasantFrom)
            moveHistoryElement.toFields.updateValue(piecesBoard[enPasantDir.y][enPasantDir.x], forKey: enPasantDir)
        } else if isRightCastleMove {
            moveHistoryElement.fromFields.updateValue(piecesBoard[rootFile.y][7], forKey: Coordinate(x: 7, y: rootFile.y))
            moveHistoryElement.toFields.updateValue(piecesBoard[rootFile.y][5], forKey: Coordinate(x: 5, y: rootFile.y))
        } else if isLeftCastleMove {
            moveHistoryElement.fromFields.updateValue(piecesBoard[rootFile.y][0], forKey: Coordinate(x: 0, y: rootFile.y))
            moveHistoryElement.toFields.updateValue(piecesBoard[rootFile.y][3], forKey: Coordinate(x: 3, y: rootFile.y))
        }
        history.append(moveHistoryElement)
    }
    
    func goToLastGameState() {
        restoreLastMove()
        preparePlayPhase()
    }
    
    private func restoreLastMove() {
        if !history.isEmpty {
            draw = false
            checkMate = false
            
            let lastHistoryElement = history.popLast()!
            activePlayer = activePlayer == .white ? .black : .white
            resetCurrentMoves()
            currentChosenPieceCoordinate = nil
            currentTwoSteppedPawnCoordinate = lastHistoryElement.twoSteppedPawnCoordinate
            
            for file in lastHistoryElement.fromFields {
                piecesBoard[file.key.y][file.key.x] = file.value
            }
            for file in lastHistoryElement.toFields {
                piecesBoard[file.key.y][file.key.x] = file.value
            }
        }
    }
    
    
    
    private func createMovesForPiece(pCoor: Coordinate, isAttacking: Bool) {
        guard piecesBoard[pCoor.y][pCoor.x] != nil else {
            print("Choosing piece went wrong")
            return
        }
        
        piecesBoard[pCoor.y][pCoor.x]!.moveList = [:]
        
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
        if isAttacking {
            removeKingViolatingMoves(pCoor: pCoor)
        }
    }
    
    
    private func removeKingViolatingMoves(pCoor: Coordinate) {
        let moves = getMovesOf(coordinate: pCoor)
        
        for move in moves {
            if move.value {
                var isViolating = false
                let piece = getPiece(at: pCoor)!
                setState(chosenPiece: piece, pieceCoordinate: pCoor, destination: move.key)
                saveMove(rootFile: pCoor, destFile: move.key)
                self.move()
                setNextPlayer()
                _ = createMovesForPlayer(isActive: false)
                
                setNextPlayer()
                let kingCoordinate = getKingCoor()!
                if isKingViolated(kCoor: kingCoordinate) {
                    isViolating = true
                }
                setNextPlayer()
                restoreLastMove()
                piecesBoard[pCoor.y][pCoor.x]!.moveList.updateValue(!isViolating, forKey: move.key)
            }
        }
    }
    
    private func resetCurrentMoves() {
        currentMoves = [:]
    }
    
    private func appendIfCorrect(pCoor: Coordinate, cursor: Coordinate) -> Bool {
        if isCoordinateOutOfBounds(cursor) { return false }
        
        guard let destPiece = piecesBoard[cursor.y][cursor.x] else {
            piecesBoard[pCoor.y][pCoor.x]!.moveList.updateValue(true, forKey: cursor)
            return true
        }
        
        if destPiece.color != piecesBoard[pCoor.y][pCoor.x]!.color  {
            piecesBoard[pCoor.y][pCoor.x]!.moveList.updateValue(true, forKey: cursor)
            return false
        }
        return false
    }
    
    private func isCoordinateOutOfBounds(_ coordinate: Coordinate) -> Bool {
        return coordinate.x < 0 || coordinate.x > columns-1 || coordinate.y < 0 || coordinate.y > rows-1
    }
    
    private func getColorOfPiece(at: Coordinate) -> PieceColor {
        guard let piece = piecesBoard[at.y][at.x] else {
            print("no piece at coordinate")
            return .black
        }
        return piece.color
    }
    
    private func getPiece(at: Coordinate) -> Piece? {
        return piecesBoard[at.y][at.x]
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
        
        if currentTwoSteppedPawnCoordinate == cursor {
            if getColorOfPiece(at: currentTwoSteppedPawnCoordinate!) != piece.color {
                cursor.y = pCoor.y + direction
                _ = appendPawnMoveIfCorrect(pCoor: pCoor, cursor: cursor)
            }
        }
        
        
        cursor.x = pCoor.x + 1
        cursor.y = pCoor.y
        if currentTwoSteppedPawnCoordinate == cursor {
            if getColorOfPiece(at: currentTwoSteppedPawnCoordinate!) != piece.color {
                cursor.y = pCoor.y + direction
                _ = appendPawnMoveIfCorrect(pCoor: pCoor, cursor: cursor)
            }
        }

        cursor = Coordinate(x: pCoor.x, y: pCoor.y + direction)
        _ = appendPawnMoveIfCorrect(pCoor: pCoor, cursor: cursor)
        cursor.y += direction
        if !piece.moved && !isCoordinateOutOfBounds(cursor) {
            if piecesBoard[cursor.y - direction][cursor.x] == nil {
                _ = appendPawnMoveIfCorrect(pCoor: pCoor, cursor: cursor)
            }
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
    }
    
    private func isKingViolated(kCoor: Coordinate) -> Bool {
        for j in 0...(rows-1) {
            for i in 0...(columns-1) {
                guard piecesBoard[j][i] != nil else { continue }
                guard piecesBoard[j][i]!.color != activePlayer else { continue }
                
                createMovesForPiece(pCoor: Coordinate(x: i, y: j), isAttacking: false)
                
                for move in piecesBoard[j][i]!.moveList {
                    if move.key == kCoor && move.value {
                        return true
                    }
                }
            }
        }
        return false
    }
    
    private func getKingCoor() -> Coordinate? {
        for j in 0...(rows-1) {
            for i in 0...(columns-1) {
                guard let piece = piecesBoard[j][i] else { continue }
                guard piece.color == activePlayer else { continue }
                guard piece.type == .king else { continue }
                
                return Coordinate(x: i, y: j)
            }
        }
        return nil
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
