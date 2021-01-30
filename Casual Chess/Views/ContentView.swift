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
    
    let boardWidth = UIScreen.screenWidth > UIScreen.screenHeight ? UIScreen.screenHeight : UIScreen.screenWidth
    let sizeFactor: CGFloat = 8.75
    
    @ObservedObject var game = ChessBoardGame()
    
    var body: some View {
        ZStack {
            Canvas()
            ChessBoard(sizeFactor: sizeFactor, width: boardWidth)
            ChessPlayGrid(game: game, sizeFactor: sizeFactor, width: boardWidth)
            VStack {
                Spacer()
                HStack {
                    Button ("Zurücksetzen") {
                        game.restart()
                    }
                    .buttonStyle(ChessButtonStyle())
                    Button(action: {
                        game.goToLastGameState()
                    } , label: {
                        Image(systemName: "arrowshape.turn.up.backward.fill")
                    })
                    .buttonStyle(ChessButtonStyle())
                }
            }
            if game.pawnReplacementCoordinate != nil {
                PieceReplacementDialog(color: game.activePlayer, coordinate: game.pawnReplacementCoordinate!, sizeFactor: sizeFactor, width: boardWidth, choosenType: nil, game: game)
            } else if game.checkMate {
                MessageView(message: "Schachmatt")
            } else if game.draw {
                MessageView(message: "Unentschieden")
            } else {
                Color(.clear)
            }
        }
    }
}

struct ContentView_Previews: PreviewProvider {
    static var previews: some View {
        ContentView()
    }
}
