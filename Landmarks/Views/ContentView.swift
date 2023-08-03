//
//  ContentView.swift
//  Landmarks
//
//  Created by nikunj dixit on 7/6/23.
//

import SwiftUI


struct ContentView: View {
    @StateObject var contentVM = ContentVM()

    var body: some View {
        NavigationView {
            VStack {
                NavigationLink("Open the Object Detection") {
                    ObjectDetectionView()
                }
            }
        }
    }
}



