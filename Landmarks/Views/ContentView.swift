//
//  ContentView.swift
//  Landmarks
//
//  Created by nikunj dixit on 7/6/23.
//

import SwiftUI
import AVFoundation


struct ContentView: View {
    @StateObject var contentVM = ContentVM()
    @State var synthesizer = AVSpeechSynthesizer()

    func synthesizeSpeech(_ text: String) {
        let utterance = AVSpeechUtterance(string: text)
        utterance.voice = AVSpeechSynthesisVoice(language: "en-US")
        utterance.pitchMultiplier = 1.0
        utterance.rate = 0.55
        synthesizer.speak(utterance)
    }
    
    var body: some View {
        NavigationView {
            List {
                NavigationLink("Open the Object Detection") {
                    
                    ObjectDetectionView()
                    
                }
                Button("Speak"){
                    synthesizeSpeech("Speech")
                }
            }
        }
    }
}



