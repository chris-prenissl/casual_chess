//
//  ChessButton.swift
//  Casual Chess
//
//  Created by Christoph Prenissl on 19.01.21.
//

import Foundation
import SwiftUI


struct ChessButtonStyle: ButtonStyle {
    
    func makeBody(configuration: Self.Configuration) -> some View {
        configuration.label
            .foregroundColor(Color("lightMain"))
            .padding()
            .background(Color(.brown))
            .cornerRadius(10)
            .padding()
    }
}
