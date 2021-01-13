//
//  ContentView.swift
//  Casual Chess
//
//  Created by Christoph Prenissl on 10.01.21.
//

import SwiftUI

extension UIScreen {
    static let screenWidth = UIScreen.main.bounds.size.width
    static let screenHeight = UIScreen.main.bounds.size.height
    static let screenSize = UIScreen.main.bounds.size
}

struct ContentView: View {
    
    let board = ChessBoard()
    let sizeFactor: CGFloat = 8.75
    
    var body: some View {
        ZStack {
            LinearGradient(gradient: Gradient(colors: [Color.black, Color("darkBrown"), Color("lightBrown")]), startPoint: .topLeading, endPoint: .bottomTrailing)
                .ignoresSafeArea()
            ChessBoardGrid(sizeFactor: sizeFactor)
            ChessPiecesGrid(rows: 8, columns: 8, board: ChessBoard(), sizeFactor: sizeFactor)
        }
    }
}

struct ChessBoardGrid: View {
    let sizeFactor: CGFloat
    
    var body: some View {
        ZStack {
            Color("darkBrown")
                .frame(width: UIScreen.screenWidth * 0.96, height: UIScreen.screenWidth * 0.96, alignment: /*@START_MENU_TOKEN@*/.center/*@END_MENU_TOKEN@*/)
            VStack(alignment: /*@START_MENU_TOKEN@*/.center/*@END_MENU_TOKEN@*/, spacing: 0){
                ForEach(0..<8, id: \.self) { row in
                    HStack(alignment: .center, spacing: 0) {
                        ForEach(0..<8, id: \.self) { column in
                            if ((row % 2 == 0 && column % 2 == 0) || (row % 2 == 1 && column % 2 == 1)) {
                                Color("lightBrown")
                                    .frame(width: UIScreen.screenWidth / sizeFactor, height: UIScreen.screenWidth / sizeFactor, alignment: /*@START_MENU_TOKEN@*/.center/*@END_MENU_TOKEN@*/)
                            } else {
                                Color("darkBrown")
                                    .frame(width: UIScreen.screenWidth / sizeFactor, height: UIScreen.screenWidth / sizeFactor, alignment: /*@START_MENU_TOKEN@*/.center/*@END_MENU_TOKEN@*/)
                            }
                        }
                    }
                }
            }
        }
    }
}

struct ChessPiecesGrid: View {
    let rows: Int
    let columns: Int
    let board: ChessBoard
    let sizeFactor: CGFloat
    
    var body: some View {
        VStack (alignment: /*@START_MENU_TOKEN@*/.center/*@END_MENU_TOKEN@*/, spacing: 0){
            ForEach(0..<rows, id: \.self) { row in
                HStack(alignment: /*@START_MENU_TOKEN@*/.center/*@END_MENU_TOKEN@*/, spacing: 0){
                    ForEach(0..<columns, id: \.self) { column in
                        PieceView(piece: board.board[row][column], sizeFactor: sizeFactor)
                    }
                }
            }
        }
    }
}

struct PieceView : View {
    let piece: Piece?
    let sizeFactor : CGFloat
    
    var body: some View {
        if (piece != nil) {
            Image(piece!.url)
                .resizable()
                .frame(width: UIScreen.screenWidth / sizeFactor, height: UIScreen.screenWidth / sizeFactor, alignment: /*@START_MENU_TOKEN@*/.center/*@END_MENU_TOKEN@*/)
        } else {
            Image("")
                .resizable()
                .frame(width: UIScreen.screenWidth / sizeFactor, height: UIScreen.screenWidth / sizeFactor, alignment: /*@START_MENU_TOKEN@*/.center/*@END_MENU_TOKEN@*/)
        }
        
    }
}

struct ContentView_Previews: PreviewProvider {
    static var previews: some View {
        ContentView()
    }
}
