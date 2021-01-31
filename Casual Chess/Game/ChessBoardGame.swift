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
        var fromFields = [field]()
        var toFields = [field]()
        var twoSteppedPawnCoordinate : Coordinate? = nil
        
        struct field {
            var coordinate: Coordinate
            var piece: Piece?
        }
    }
    
    var testConfig: [[Piece?]] = Array(repeating: Array(repeating: nil, count: 8), count: 8)
    
    
    let rows = 8, columns = 8
    
    @Published var piecesBoard: [[Piece?]]
    var startingConfiguration = normalConfiguration
    var history = [historyElement]()
    
    //player
    @Published var activePlayer: PieceColor = .white
    @Published var currentChosenPieceCoordinate: Coordinate?
    @Published var currentMoves = [Coordinate : Bool]()
    
    //game states
    @Published var pawnReplacementCoordinate: Coordinate? = nil
    @Published var kingHasToMove = false
    @Published var checkMate = false
    @Published var draw = false
    
    //move type
    var isLeftCastleMove = false
    var isRightCastleMove = false
    var isEnPasantMove = false
    
        
    init() {
        startingConfiguration = normalConfiguration
        piecesBoard = startingConfiguration
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
        
        preparePlayPhase()
    }
    
    private func preparePlayPhase() {
        let cannotMove = !createMovesForPlayer(isActive: true)
        check()
        draw = cannotMove
    }
    
    private func createMovesForPlayer(isActive: Bool) -> Bool {
        var count = 0
        for i in 0...(rows-1) {
            for j in 0...(columns-1) {
                guard let piece = piecesBoard[i][j] else { continue }
                guard piece.color == activePlayer else { continue }
                
                createMovesForPiece(pCoor: Coordinate(x: j, y: i), isAttacking: isActive)
                
                for move in piecesBoard[i][j]!.moveList {
                    if move.value {
                        count += 1
                    }
                }
            }
        }
        return count > 0
    }
    
    private func check() {
        guard let kCoor = getKingCoor() else {
            print("No king found")
            return
        }
        if isKingViolated(kCoor: kCoor) {
            checkMate = !checkIfNonKingViolatingMoveExists()
        }
    }
    
    private func checkIfNonKingViolatingMoveExists() -> Bool {
        for i in 0..<rows {
            for j in 0..<columns {
                guard let piece = piecesBoard[i][j] else { continue }
                guard piece.color == activePlayer else { continue }
                
                for move in piece.moveList {
                    if move.value { return true }
                }
            }
        }
        return false
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
        saveMove(rootFile: pieceCoordinate, destFile: destination)
        move()
        
        pawnReplacementCoordinate = checkIfNeededToChoosePawnReplacement()
        
        guard pawnReplacementCoordinate == nil else { return }
        //prepare for next player
        setNextPlayer()
        preparePlayPhase()
    }
    
    func replace(at: Coordinate, with type: PieceType) {
        piecesBoard[at.y][at.x]!.type = type
        pawnReplacementCoordinate = nil
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
    }
    
    private func checkIfNeededToChoosePawnReplacement() -> Coordinate? {
        
        if activePlayer == .white {
            for i in 0..<columns {
                guard let piece = piecesBoard[0][i] else { continue }
                
                if piece.color == .white && piece.type == .pawn {
                    return Coordinate(x: i, y: 0)
                }
            }
        } else {
            for i in 0..<columns {
                guard let piece = piecesBoard[rows-1][i] else { continue }
                
                if piece.color == .black && piece.type == .pawn {
                    return Coordinate(x: i, y: rows-1)
                }
            }
            
        }
        
        return nil
    }
    
    private func move() {
        guard let lastHistoryElement = history.last else {
            print("No element in history")
            return
        }
        var from = lastHistoryElement.fromFields
        var to = lastHistoryElement.toFields
        
        while !from.isEmpty {
            let fromField = from.popLast()!
            let toField = to.popLast()!
            piecesBoard[fromField.coordinate.y][fromField.coordinate.x] = nil
            piecesBoard[toField.coordinate.y][toField.coordinate.x] = fromField.piece
            if piecesBoard[toField.coordinate.y][toField.coordinate.x] != nil {
                piecesBoard[toField.coordinate.y][toField.coordinate.x]!.moved = true
            }
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
            guard let twoSteppedcoordinate = history.last?.twoSteppedPawnCoordinate else {
                return false
            }
            if twoSteppedcoordinate == Coordinate(x: coordinate.x, y: coordinate.y + enemyPawnDir) {
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
        
        moveHistoryElement.twoSteppedPawnCoordinate = twoSteppedPawnMove(from: rootFile, destination: destFile)
        
        moveHistoryElement.fromFields.append(historyElement.field(coordinate: rootFile, piece: piecesBoard[rootFile.y][rootFile.x]))
        moveHistoryElement.toFields.append(historyElement.field(coordinate: destFile, piece: piecesBoard[destFile.y][destFile.x]))
        
        if isEnPasantMove {
            let enemyDir = activePlayer == .white ? 1 : -1
            let enPasantFrom = Coordinate(x: destFile.x, y: destFile.y + enemyDir)
            let enPasantDir = Coordinate(x: destFile.x, y: destFile.y + enemyDir)
            moveHistoryElement.fromFields.append(historyElement.field(coordinate: enPasantFrom, piece: nil))
            moveHistoryElement.toFields.append(historyElement.field(coordinate: enPasantDir, piece: piecesBoard[enPasantDir.y][enPasantDir.x]))
        } else if isRightCastleMove {
            moveHistoryElement.fromFields.append(historyElement.field(coordinate: Coordinate(x: 7, y: rootFile.y), piece: piecesBoard[rootFile.y][7]))
            moveHistoryElement.toFields.append(historyElement.field(coordinate: Coordinate(x: 5, y: rootFile.y), piece: piecesBoard[rootFile.y][5]))
        } else if isLeftCastleMove {
            moveHistoryElement.fromFields.append(historyElement.field(coordinate: Coordinate(x: 0, y: rootFile.y), piece: piecesBoard[rootFile.y][0]))
            moveHistoryElement.toFields.append(historyElement.field(coordinate: Coordinate(x: 3, y: rootFile.y), piece: piecesBoard[rootFile.y][3]))
        }
        
        history.append(moveHistoryElement)
    }
    
    func goToLastGameState() {
        if !history.isEmpty {
            draw = false
            checkMate = false
            resetCurrentMoves()
            currentChosenPieceCoordinate = nil
            
            let beforeMove = history.popLast()!
            
            for file in beforeMove.fromFields {
                piecesBoard[file.coordinate.y][file.coordinate.x] = file.piece
            }
            for file in beforeMove.toFields {
                piecesBoard[file.coordinate.y][file.coordinate.x] = file.piece
            }
            
            setNextPlayer()
            preparePlayPhase()
        }
        
    }
    
    private func revokeLastMove() {
        draw = false
        checkMate = false
        
        resetCurrentMoves()
        currentChosenPieceCoordinate = nil
        
        guard let lastHistoryElement = history.popLast() else {
            print("No element in history")
            return
        }
        var from = lastHistoryElement.fromFields
        var to = lastHistoryElement.toFields
        
        while !from.isEmpty {
            let fromField = from.popLast()!
            let toField = to.popLast()!
            piecesBoard[fromField.coordinate.y][fromField.coordinate.x] = fromField.piece
            piecesBoard[toField.coordinate.y][toField.coordinate.x] = toField.piece
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
                revokeLastMove()
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
        let twoSteppedPawnCoordinate = history.last?.twoSteppedPawnCoordinate
        
        let direction = piecesBoard[pCoor.y][pCoor.x]!.color == .white ? -1 : 1
        var cursor = Coordinate(x: pCoor.x, y: pCoor.y)
        

        cursor.x = pCoor.x - 1
        
        if twoSteppedPawnCoordinate  == cursor {
            if getColorOfPiece(at: twoSteppedPawnCoordinate!) != piece.color {
                cursor.y = pCoor.y + direction
                _ = appendPawnMoveIfCorrect(pCoor: pCoor, cursor: cursor)
            }
        }
        
        
        cursor.x = pCoor.x + 1
        cursor.y = pCoor.y
        if twoSteppedPawnCoordinate == cursor {
            if getColorOfPiece(at: twoSteppedPawnCoordinate!) != piece.color {
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
            
        if piece?.color != activePlayer {
            
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


let normalConfiguration = [[Piece(type: .rook, color: .black), Piece(type: .knight, color: .black), Piece(type: .bishop, color: .black), Piece(type: .queen, color: .black), Piece(type: .king, color: .black), Piece(type: .bishop, color: .black), Piece(type: .knight, color: .black), Piece(type: .rook, color: .black)],
                             [Piece(type: .pawn, color: .black), Piece(type: .pawn, color: .black), Piece(type: .pawn, color: .black), Piece(type: .pawn, color: .black), Piece(type: .pawn, color: .black), Piece(type: .pawn, color: .black), Piece(type: .pawn, color: .black), Piece(type: .pawn, color: .black)],
                             [nil, nil, nil, nil, nil, nil, nil, nil],
                             [nil, nil, nil, nil, nil, nil, nil, nil],
                             [nil, nil, nil, nil, nil, nil, nil, nil],
                             [nil, nil, nil, nil, nil, nil, nil, nil],
                             [Piece(type: .pawn, color: .white), Piece(type: .pawn, color: .white), Piece(type: .pawn, color: .white), Piece(type: .pawn, color: .white), Piece(type: .pawn, color: .white), Piece(type: .pawn, color: .white), Piece(type: .pawn, color: .white), Piece(type: .pawn, color: .white)],
                             [Piece(type: .rook, color: .white), Piece(type: .knight, color: .white), Piece(type: .bishop, color: .white), Piece(type: .queen, color: .white), Piece(type: .king, color: .white), Piece(type: .bishop, color: .white), Piece(type: .knight, color: .white), Piece(type: .rook, color: .white)]]



