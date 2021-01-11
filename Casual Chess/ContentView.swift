//
//  ContentView.swift
//  Casual Chess
//
//  Created by Christoph Prenissl on 10.01.21.
//

import SwiftUI

struct ContentView: View {
    
    let board = ChessBoard()
    
    var body: some View {
        ZStack {
            Image("chess_board")
                .resizable()
                .frame(width: CGFloat(board.rows) * 100, height: CGFloat(board.columns) * 100, alignment: /*@START_MENU_TOKEN@*/.center/*@END_MENU_TOKEN@*/)
            ChessGrid(rows: 8, columns: 8, board: ChessBoard())
        }
    }
}

struct ChessGrid: View {
    let rows: Int
    let columns: Int
    let board: ChessBoard
    
    var body: some View {
        VStack {
            ForEach(0..<rows, id: \.self) { row in
                HStack {
                    ForEach(0..<columns, id: \.self) { column in
                        PieceView(piece: board.board[row][column])
                    }
                }
            }
        }
    }
}

struct PieceView : View {
    let piece: Piece?
    
    var body: some View {
        if (piece != nil) {
            Image(piece!.url)
        } else {
            Image("")
                .frame(width: 90, height: 90, alignment: .center)
        }
        
    }
}

struct ContentView_Previews: PreviewProvider {
    static var previews: some View {
        ContentView()
    }
}
