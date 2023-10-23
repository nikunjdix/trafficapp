//
//  ObjectDetectionVM.swift
//  Reference
//
//  Created by Prateek Prakash on 8/1/22.
//

import AVFoundation
import SwiftUI
import UIKit
import Vision

class ObjectDetectionVM: NSObject, ObservableObject {
    @Published var cgImage: CGImage?
    @Published var currentBuffer: CVPixelBuffer?
    @Published var boundingBoxes: [CGRect] = []
    @Published var boxLabels: [String] = []
    
    @State var synthesizer = AVSpeechSynthesizer()
    var wasOnScreen = false
    var isOnScreen = false
    

    func synthesizeSpeech(_ text: String) {
        let utterance = AVSpeechUtterance(string: text)
        utterance.voice = AVSpeechSynthesisVoice(language: "en-US")
        utterance.pitchMultiplier = 1.0
        utterance.rate = 0.55
        synthesizer.speak(utterance)
    }
    
    let videoOutputQueue = DispatchQueue(label: "VideoOutputQ", qos: .userInitiated, attributes: [], autoreleaseFrequency: .workItem)
    
    private let context = CIContext()
    private let cameraManager = CameraManager.shared
    
    private var requests = [VNRequest]()
    
    override init() {
        super.init()
        
        // Capture Delegate
        CameraManager.shared.setDelegate(self, queue: videoOutputQueue)
        
        // Core ML Model
        setupVision()
        
        // CGImage
        $currentBuffer
            .receive(on: RunLoop.main)
            .compactMap { buffer in
                guard let image = CGImage.create(from: buffer) else {
                    return nil
                }
                let ciImage = CIImage(cgImage: image)
                return self.context.createCGImage(ciImage, from: ciImage.extent)
            }
            .assign(to: &$cgImage)
    }
    
    @discardableResult
    func setupVision() -> NSError? {
        let error: NSError! = nil
        
        guard let modelUrl = Bundle.main.url(forResource: "TrafficSign", withExtension: "mlmodelc") else {
            return NSError(domain: "ObjectDetectionVM", code: -1, userInfo: [NSLocalizedDescriptionKey: "Missing Core ML Model File"])
        }
        do {
            let visionModel = try VNCoreMLModel(for: MLModel(contentsOf: modelUrl))
            let objectRecognition = VNCoreMLRequest(model: visionModel, completionHandler: { request, error in
                DispatchQueue.main.async {
                    if let results = request.results {
                        self.wasOnScreen = !self.boxLabels.isEmpty
                        self.boundingBoxes = []
                        self.boxLabels = []
                        for observation in results where observation is VNRecognizedObjectObservation {
                            guard let objectObservation = observation as? VNRecognizedObjectObservation else {
                                continue
                            }
                            let topLabel = objectObservation.labels[0]
                            let formatter = NumberFormatter()
                            formatter.numberStyle = .decimal
                            formatter.minimumFractionDigits = 2
                            formatter.maximumFractionDigits = 2
                            let confidence = formatter.string(from: topLabel.confidence as NSNumber)!
                            let identifier = topLabel.identifier.uppercased()
                            let box = objectObservation.boundingBox
//                            if identifier == "TRAFFIC LIGHT" {
                                //print(identifier)
                                //print(confidence)
                                if let cgImage = self.cgImage {
                                    let flipped = CGRect(x: box.origin.x, y: 1 - box.origin.y, width: box.width, height: box.height)
                                    let converted = VNImageRectForNormalizedRect(flipped, cgImage.width, cgImage.height)
                                    let fixed = CGRect(x: converted.origin.x, y: converted.origin.y - converted.height, width: converted.width, height: converted.height)
                                    self.boundingBoxes.append(fixed)
                                    self.boxLabels.append(identifier)
                                }
//                            }
                            print("\(confidence) • \(identifier)")
                            //print(box)
                           
                            
                        }
//                        print(self.boxLabels)
                        self.isOnScreen = !self.boxLabels.isEmpty
//                        print(self.wasOnScreen)
//                        print(self.isOnScreen)
//                        if !self.wasOnScreen && self.isOnScreen {
//                            self.synthesizeSpeech("Traffic Light")
//                        }
                    }
                }
            })
            self.requests = [objectRecognition]
        } catch let error as NSError {
            print(error.localizedDescription)
        }
        
        return error
    }
}

extension ObjectDetectionVM: AVCaptureVideoDataOutputSampleBufferDelegate {
    func captureOutput(_ output: AVCaptureOutput, didOutput sampleBuffer: CMSampleBuffer, from connection: AVCaptureConnection) {
        if let buffer = sampleBuffer.imageBuffer {
            DispatchQueue.main.async {
                self.currentBuffer = buffer
            }
        }
        
        guard let pixelBuffer = CMSampleBufferGetImageBuffer(sampleBuffer) else {
            return
        }
        
        DispatchQueue.global(qos: .background).async {
            let handler = VNImageRequestHandler(cvPixelBuffer: pixelBuffer, orientation: .up, options: [:])
            do {
                try handler.perform(self.requests)
            } catch {
                print(error)
            }
        }
    }
}
