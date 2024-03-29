//
//  PreviewView.swift
//  ObjectSeparation
//
//  Created by Horus on 2023/03/04.
//

import UIKit
import AVFoundation

final class PreviewView: UIView {
    
    var videoPreviewLayer: AVCaptureVideoPreviewLayer {
        guard let layer = layer as? AVCaptureVideoPreviewLayer else {
            fatalError("Expected `AVCaptureVideoPreviewLayer` type for layer. Check PreviewView.layerClass implementation.")
        }
        return layer
    }
    
    override class var layerClass: AnyClass {
        return AVCaptureVideoPreviewLayer.self
    }
    
}
