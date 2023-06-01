//
//  OverlayView.swift
//  SyarahObjectDetection
//
//  Created by Khaled on 01/06/2023.
//

import SwiftUI

/**
 This structure holds the display parameters for the overlay to be drawn on a detected object.
 */
struct ObjectOverlay: Identifiable {
    let id: UUID = UUID()
    let name: String
    let boundingBox: CGRect
    let imageSize: CGSize
    let color: Color
}

struct OverlayView: View {
    
    var objectOverlays = [ObjectOverlay]()
    
    private let cornerRadius: CGFloat = 10.0
    private let stringBgAlpha: CGFloat = 0.7
    private let lineWidth: CGFloat = 3
    private let stringFontColor = UIColor.white
    private let stringHorizontalSpacing: CGFloat = 13.0
    private let stringVerticalSpacing: CGFloat = 7.0
    
    var body: some View {
        GeometryReader { proxy in
            ZStack(alignment: .topLeading) {
                ForEach(objectOverlays) { overlay in
                    let rect = rect(for: overlay, viewSize: proxy.size)
                    border(of: overlay, in: rect)
                    name(of: overlay, in: rect)
                }
            }
        }
    }
    
    /// Rect for overlay after applying transform based on view size
    /// - Parameters:
    ///   - objectOverlay: objectOverlay object
    ///   - viewSize: superview size for transformation
    /// - Returns: new CGRect after transormation
    private func rect(for objectOverlay: ObjectOverlay, viewSize: CGSize) -> CGRect {
        // Translates bounding box rect to current view.
        var convertedRect = objectOverlay.boundingBox.applying(
            CGAffineTransform(
                scaleX: viewSize.width / objectOverlay.imageSize.width,
                y: viewSize.height / objectOverlay.imageSize.height
            )
        )
        
        if convertedRect.origin.x < 0 {
            convertedRect.origin.x = 2
        }
        
        if convertedRect.origin.y < 0 {
            convertedRect.origin.y = 2
        }
        
        if convertedRect.maxY > viewSize.height {
            convertedRect.size.height =
            viewSize.height - convertedRect.origin.y - 2
        }
        
        if convertedRect.maxX > viewSize.width {
            convertedRect.size.width =
            viewSize.width - convertedRect.origin.x - 2
        }

        return convertedRect
    }
    
    
    /// Returns the border view of this overlay
    /// - Parameters:
    ///   - overlay: To be displayed
    ///   - rect: rect to displayed in
    /// - Returns: The view of overlay name
    private func border(of overlay: ObjectOverlay, in rect: CGRect) -> some View {
        Rectangle()
            .stroke(lineWidth: lineWidth)
            .foregroundColor(overlay.color)
            .frame(width: rect.width, height: rect.height)
            .padding(.leading, rect.minX)
            .padding(.top, rect.minY)
    }
    
    
    /// Returns the Text name view of this overlay
    /// - Parameters:
    ///   - overlay: To be displayed
    ///   - rect: rect to displayed in
    /// - Returns: The view of overlay name
    private func name(of overlay: ObjectOverlay, in rect: CGRect) -> some View {
        Text(overlay.name)
            .foregroundColor(.white)
            .font(.footnote)
            .padding(4)
            .background(overlay.color)
            .padding(.leading, rect.minX)
            .padding(.top, rect.minY)
    }
    
}
