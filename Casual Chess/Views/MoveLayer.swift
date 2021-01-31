//
//  MoveLayer.swift
//  Casual Chess
//
//  Created by Christoph Prenissl on 17.01.21.
//

import Foundation
import SwiftUI

struct ChessPlayGrid: View {
    
    @ObservedObject var game: ChessBoardGame

    let sizeFactor: CGFloat
    let width: CGFloat
    
    var body: some View {
        
        return VStack (alignment: /*@START_MENU_TOKEN@*/.center/*@END_MENU_TOKEN@*/, spacing: 0){
            ForEach(0..<game.rows, id: \.self) { row in
                HStack(alignment: /*@START_MENU_TOKEN@*/.center/*@END_MENU_TOKEN@*/, spacing: 0){
                    ForEach(0..<game.columns, id: \.self) { column in
                        let tapGesture = TapGesture(count: 1)
                            .onEnded {
                                if !game.kingHasToMove && !game.draw && game.activePlayer == game.piecesBoard[row][column]?.color {
                                    game.setCurrentChosenPiece(coordinate: Coordinate(x: column, y: row))
                                } else if game.currentMoves[Coordinate(x: column, y: row)] ?? false {
                                    game.tryToMovePieceTo(x: column, y: row)
                                }
                            }
                        let borderColor = game.currentMoves[Coordinate(x: column, y: row)] == false ? Color("purple") : Color("green")
                        PieceView(piece: game.piecesBoard[row][column], sizeFactor: sizeFactor, width: width)
                            .gesture(tapGesture)
                            .background(game.currentChosenPieceCoordinate?.x == column && game.currentChosenPieceCoordinate?.y == row ? Color(.cyan) : Color(.clear))
                            .border(game.currentMoves[Coordinate(x: column, y: row)] == nil ? Color(.clear) : borderColor, width: 4)
                    }
                }
            }
        }
    }
}
