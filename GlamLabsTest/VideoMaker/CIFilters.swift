//
//  CIFilters.swift
//  GlamLabsTest
//
//  Created by Роман Анпилов on 19.03.2023.
//

import Foundation
import AVFoundation
import CoreImage

extension CIFilter {
    static func blendWithMask(
        inputImage: CIImage,
        inputBackgroundImage: CIImage? = nil,
        inputMaskImage: CIImage
    ) -> CIImage? {
        guard let filter = CIFilter(name: "CIBlendWithMask") else {
            return nil
        }
        filter.setDefaults()
        filter.setValue(inputImage, forKey: kCIInputImageKey)
        filter.setValue(inputBackgroundImage, forKey: kCIInputBackgroundImageKey)
        filter.setValue(inputMaskImage, forKey: kCIInputMaskImageKey)
        return filter.outputImage
    }
    
    static func colorInvert(inputImage: CIImage) -> CIImage? {
        guard let filter = CIFilter(name: "CIColorInvert") else {
            return nil
        }
        filter.setDefaults()
        filter.setValue(inputImage, forKey: kCIInputImageKey)
        return filter.outputImage
    }
    
    static func straightenFilter(
        inputImage: CIImage,
        inputAngle: NSNumber = 0
    ) -> CIImage? {
        guard let filter = CIFilter(name: "CIStraightenFilter") else {
            return nil
        }
        filter.setDefaults()
        filter.setValue(inputImage, forKey: kCIInputImageKey)
        filter.setValue(inputAngle, forKey: kCIInputAngleKey)
        return filter.outputImage
    }
    
    static func sourceOverCompositing(
        inputImage: CIImage,
        inputBackgroundImage: CIImage
    ) -> CIImage? {
        guard let filter = CIFilter(name: "CISourceOverCompositing") else {
            return nil
        }
        filter.setDefaults()
        filter.setValue(inputImage, forKey: kCIInputImageKey)
        filter.setValue(inputBackgroundImage, forKey: kCIInputBackgroundImageKey)
        return filter.outputImage
    }
    
    static func lanczosScaleTransform(
        inputImage: CIImage,
        inputScale: NSNumber = 1,
        inputAspectRatio: NSNumber = 1
    ) -> CIImage? {
        guard let filter = CIFilter(name: "CILanczosScaleTransform") else {
            return nil
        }
        filter.setDefaults()
        filter.setValue(inputImage, forKey: kCIInputImageKey)
        filter.setValue(inputScale, forKey: kCIInputScaleKey)
        filter.setValue(inputAspectRatio, forKey: "inputAspectRatio")
        return filter.outputImage
    }
    
    static func affineTransform(
        inputImage: CIImage,
        inputTransform: NSValue = NSValue(cgAffineTransform: CGAffineTransform(a: 1.0, b: 0.0, c: 0.0, d: 1.0, tx: 0.0, ty: 0.0))
    ) -> CIImage? {
        guard let filter = CIFilter(name: "CIAffineTransform") else {
            return nil
        }
        filter.setDefaults()
        filter.setValue(inputImage, forKey: kCIInputImageKey)
        filter.setValue(inputTransform, forKey: kCIInputTransformKey)
        return filter.outputImage
    }
}
