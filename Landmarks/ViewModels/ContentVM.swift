//
//  ContentVM.swift
//  Landmarks
//
//  Created by nikunj dixit on 7/6/23.
//
import AVFoundation
import UIKit
import Foundation



class ContentVM: ObservableObject {
    @Published var placeholderText: String = "Hello"
    
    func updatePlaceholder(_ text: String) {
        placeholderText = text
    }
}


