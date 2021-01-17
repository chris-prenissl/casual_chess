//
//  PieceView.swift
//  Casual Chess
//
//  Created by Christoph Prenissl on 17.01.21.
//

import Foundation
import SwiftUI

struct PieceView : View {
    let piece: Piece?
    let sizeFactor : CGFloat
    let width: CGFloat
    
    var body: some View {
        
        if (piece != nil) {
            Image(piece!.url)
                .resizable()
                .frame(width: width / sizeFactor, height: width / sizeFactor, alignment: /*@START_MENU_TOKEN@*/.center/*@END_MENU_TOKEN@*/)
        } else {
            Color(.clear)
                .frame(width: width / sizeFactor, height: width / sizeFactor, alignment: /*@START_MENU_TOKEN@*/.center/*@END_MENU_TOKEN@*/)
                .contentShape(Rectangle())
        }
        
    }
}
