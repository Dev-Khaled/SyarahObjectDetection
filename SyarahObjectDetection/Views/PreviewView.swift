//
//  PreviewView.swift
//  SyarahObjectDetection
//
//  Created by Khaled on 01/06/2023.
//

import SwiftUI
import AVFoundation

struct PreviewView: UIViewRepresentable {
    
    let uiView = PreviewUIView()
    
    func makeUIView(context: Context) -> PreviewUIView {
        uiView
    }

    func updateUIView(_ uiView: PreviewUIView, context: Context) {
        // Do nothing
    }
}

struct PreviewView_Previews: PreviewProvider {
    static var previews: some View {
        PreviewView()
    }
}
