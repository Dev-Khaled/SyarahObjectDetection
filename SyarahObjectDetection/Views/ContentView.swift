//
//  ContentView.swift
//  SyarahObjectDetection
//
//  Created by Khaled on 01/06/2023.
//

import SwiftUI

struct ContentView: View {
    var body: some View {
        VStack {
            Text("Sample Syarah 🚕 AI OD App")
            MainView()
        }
        .padding()
    }
}

struct ContentView_Previews: PreviewProvider {
    static var previews: some View {
        ContentView()
    }
}
