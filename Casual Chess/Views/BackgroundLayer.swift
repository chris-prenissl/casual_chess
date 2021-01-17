//
//  BackgroundLayer.swift
//  Casual Chess
//
//  Created by Christoph Prenissl on 17.01.21.
//

import Foundation
import SwiftUI

struct Canvas: View {
    var body: some View {
        LinearGradient(gradient: Gradient(colors: [Color.black, Color("darkBrown"), Color("lightBrown")]), startPoint: .topLeading, endPoint: .bottomTrailing)
            .ignoresSafeArea()
    }
}

struct ChessBoard: View {
    let sizeFactor: CGFloat
    let width: CGFloat
    
    var body: some View {
        ZStack {
            VStack(alignment: /*@START_MENU_TOKEN@*/.center/*@END_MENU_TOKEN@*/, spacing: 0){
                ForEach(0..<8, id: \.self) { row in
                    HStack(alignment: .center, spacing: 0) {
                        ForEach(0..<8, id: \.self) { column in
                            
                            if (row % 2 == 0 && column % 2 == 1 || row % 2 == 1 && column % 2 == 0) {
                               Color("darkBrown")
                                    .frame(width: width / sizeFactor, height: width / sizeFactor, alignment: /*@START_MENU_TOKEN@*/.center/*@END_MENU_TOKEN@*/)
                            } else {
                                Color("lightBrown")
                                    .frame(width: width / sizeFactor, height: width / sizeFactor, alignment: /*@START_MENU_TOKEN@*/.center/*@END_MENU_TOKEN@*/)
                            }
                        }
                    }
                }
            }
        }
    }
}
