//
//  PieceReplacementDialog.swift
//  Casual Chess
//
//  Created by Christoph Prenissl on 30.01.21.
//

import SwiftUI

struct PieceReplacementDialog: View {
    let message = "Entscheide dich"
    let color: PieceColor
    let coordinate: Coordinate
    let sizeFactor : CGFloat
    let width: CGFloat
    
    @State var choosenType: PieceType?
    @ObservedObject var game: ChessBoardGame
    
    private func choose(type: PieceType) {
        game.replace(at: coordinate, with: type)
    }
    
    var body: some View {
        VStack {
            Text(message)
                .padding()
                .background(LinearGradient(gradient: Gradient(colors: [Color("darkBrown"), Color("lightBrown")]), startPoint: UnitPoint(x: 0, y: 1), endPoint: UnitPoint(x: 1, y: 1)))
                .border(Color("darkBrown"), width: 2)
                .cornerRadius(4)
            HStack {
                PieceView(piece: Piece(type: .queen, color: color), sizeFactor: sizeFactor, width: width)
                    .onTapGesture {
                        choose(type: .queen)
                    }
                PieceView(piece: Piece(type: .knight, color: color), sizeFactor: sizeFactor, width: width)
                    .onTapGesture {
                        choose(type: .knight)
                    }
                PieceView(piece: Piece(type: .rook, color: color), sizeFactor: sizeFactor, width: width)
                    .onTapGesture {
                        choose(type: .rook)
                    }
                PieceView(piece: Piece(type: .bishop, color: color), sizeFactor: sizeFactor, width: width)
                    .onTapGesture {
                        choose(type: .bishop)
                    }
            }
        }
    }
}
