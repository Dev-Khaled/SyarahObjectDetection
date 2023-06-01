//
//  MainView.swift
//  SyarahObjectDetection
//
//  Created by Khaled on 01/06/2023.
//

import SwiftUI
import TensorFlowLiteTaskVision

struct MainView: View {
    
    @StateObject private var viewModel = MainViewModel()
    
    var body: some View {
        GeometryReader { proxy in
            ZStack {
                viewModel.previewView
                viewModel.overlayView
                    .tag(viewModel.overlayViewTag)
                
                
                VStack {
                    if viewModel.showResumeButton {
                        Button("Resume") {
                            viewModel.onClickResumeButton()
                        }
                    }
                    if viewModel.showCameraNotAvailable {
                        Text("Camera not available")
                    }
                }
            }
        }
        .onAppear {
            viewModel.cameraFeedManager.checkCameraConfigurationAndStartSession()
            
        }
        .onDisappear {
            viewModel.cameraFeedManager.stopSession()
        }
    }
    
    
}

struct MainView_Previews: PreviewProvider {
    static var previews: some View {
        MainView()
    }
}






// MARK: View Model

@MainActor
class MainViewModel: ObservableObject {
    private(set) var previewView = PreviewView()
    @Published private(set) var overlayView = OverlayView()
    private(set) var overlayViewTag = UUID()
        
    // MARK: Model config variables
    let fileInfo = FileInfo("efficientdet_lite0", "tflite")
    let threadCount = 1
    let scoreThreshold: Float = 0.5
    let maxResults: Int = 3
    
    // Holds the results at any time
    private var result: Result?
    private let inferenceQueue = DispatchQueue(label: "com.syarah.inference.queue")
    private var isInferenceQueueBusy = false
    
    private let colors = [
        Color.red,
        Color(.displayP3, red: 90.0 / 255.0, green: 200.0 / 255.0, blue: 250.0 / 255.0, opacity: 1.0),
        Color.green,
        Color.orange,
        Color.blue,
        Color.purple,
        Color(uiColor: .magenta),
        Color.yellow,
        Color.cyan,
        Color.brown
    ]
    
    // MARK: Controllers that manage functionality
    private(set) lazy var cameraFeedManager = CameraFeedManager(
        previewView: previewView.uiView
    )
    private(set) lazy var objectDetectionHelper: ObjectDetectionHelper? = ObjectDetectionHelper(
        modelFileInfo: fileInfo,
        threadCount: threadCount,
        scoreThreshold: scoreThreshold,
        maxResults: maxResults
    )
    
    
    
    @Published var showResumeButton = false
    @Published var showCameraNotAvailable = false
    @Published var presentUnableToResumeSessionAlert = false
    
    init() {
        cameraFeedManager.delegate = self
    }
    
    
    func onClickResumeButton() {
        cameraFeedManager.resumeInterruptedSession { [weak self] complete in
            guard let self else { return }
            
            if complete {
                showResumeButton = false
                showCameraNotAvailable = false
            } else {
                presentUnableToResumeSessionAlert = true
            }
        }
    }
    
}

extension MainViewModel: CameraFeedManagerDelegate {
    func didOutput(pixelBuffer: CVPixelBuffer) {
        // Drop current frame if the previous frame is still being processed.
        guard !self.isInferenceQueueBusy else { return }
        
        inferenceQueue.async {
            self.isInferenceQueueBusy = true
            self.detect(pixelBuffer: pixelBuffer)
            self.isInferenceQueueBusy = false
        }
    }
    
    func presentCameraPermissionsDeniedAlert() {
        // TODO: TODO
    }
    
    func presentVideoConfigurationErrorAlert() {
        // TODO: TODO
    }
    
    func sessionRunTimeErrorOccurred() {
        // Handles session run time error by updating the UI and providing a button if session can be manually resumed.
        showResumeButton = true
    }
    
    func sessionWasInterrupted(canResumeManually resumeManually: Bool) {
        // Updates the UI when session is interrupted.
        if resumeManually {
            showResumeButton = true
        } else {
            showCameraNotAvailable = true
        }
        
    }
    
    func sessionInterruptionEnded() {
        // Updates UI once session interruption has ended.
        showResumeButton = false
        showCameraNotAvailable = false
    }
    
    
    // MARK: - Private
    /** This method runs the live camera pixelBuffer through tensorFlow to get the result.
     */
    private func detect(pixelBuffer: CVPixelBuffer) {
        result = self.objectDetectionHelper?.detect(frame: pixelBuffer)
        
        guard let displayResult = result else {
            return
        }
        
        let width = CVPixelBufferGetWidth(pixelBuffer)
        let height = CVPixelBufferGetHeight(pixelBuffer)
        
        DispatchQueue.main.async {
            
            // Draws the bounding boxes and displays class names and confidence scores.
            self.drawAfterPerformingCalculations(
                onDetections: displayResult.detections,
                withImageSize: CGSize(width: CGFloat(width), height: CGFloat(height))
            )
        }
    }
    
    /**
     This method takes the results, translates the bounding box rects to the current view, draws the bounding boxes, classNames and confidence scores of inferences.
     */
    func drawAfterPerformingCalculations(onDetections detections: [Detection], withImageSize imageSize: CGSize) {
        
        self.overlayView.objectOverlays = []
        
        guard !detections.isEmpty else {
            return
        }
        
        var objectOverlays: [ObjectOverlay] = []
        
        for detection in detections {
            
            guard let category = detection.categories.first else { continue }
            
            let objectDescription = String(
                format: "\(category.label ?? "Unknown") (%.2f)",
                category.score)
            
            let displayColor = colors[category.index % colors.count]
            
            let objectOverlay = ObjectOverlay(
                name: objectDescription,
                boundingBox: detection.boundingBox,
                imageSize: imageSize,
                color: displayColor
            )
            
            objectOverlays.append(objectOverlay)
        }
        
        // Hands off drawing to the OverlayView
        self.draw(objectOverlays: objectOverlays)
        
    }
    
    /** Calls methods to update overlay view with detected bounding boxes and class names.
     */
    func draw(objectOverlays: [ObjectOverlay]) {
        self.overlayView.objectOverlays = objectOverlays
        self.overlayViewTag = UUID()
    }
    
}
