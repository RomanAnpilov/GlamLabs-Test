//
//  VideoTransitions.swift
//  GlamLabsTest
//
//  Created by Роман Анпилов on 19.03.2023.
//

import AVFoundation
import CoreImage

extension Double {
    func rounded(toPlaces places:Int) -> Double {
        let divisor = pow(10.0, Double(places))
        return (self * divisor).rounded() / divisor
    }
}

protocol Transition {
    var transitionLength: CMTimeRange { get set }
    
    func getImage(
        for time: CMTime,
        currentImage: VideoImageItem,
        nextImage: VideoImageItem
    ) -> CIImage?
}

struct ScaleFront: Transition {
    var transitionLength: CMTimeRange = .init(start: .zero,
                                              end: .init(seconds: 0.6, preferredTimescale: 300))
    
    func getImage(
        for time: CMTime,
        currentImage: VideoImageItem,
        nextImage: VideoImageItem
    ) -> CIImage? {
        let scaleFactor = NSNumber(floatLiteral: 1.0 + time.seconds.rounded(toPlaces: 1))
        guard let imageForScale = CIFilter.blendWithMask(inputImage: nextImage.image,
                                                         inputMaskImage: nextImage.imageFrontPlane),
              let scaledImage = CIFilter.lanczosScaleTransform(inputImage: imageForScale,
                                                               inputScale: scaleFactor)
        else { return nil }
        
        return CIFilter.sourceOverCompositing(inputImage: scaledImage,
                                              inputBackgroundImage: currentImage.image)
    }
}

struct ScaleBackground: Transition {
    var transitionLength: CMTimeRange = .init(start: .zero,
                                              end: .init(seconds: 0.6, preferredTimescale: 300))
    
    func getImage(
        for time: CMTime,
        currentImage: VideoImageItem,
        nextImage: VideoImageItem
    ) -> CIImage? {
        guard let invertedMask = CIFilter.colorInvert(inputImage: nextImage.imageFrontPlane)
        else { return nil }
        let scaleFactor = NSNumber(floatLiteral: 1.0 + time.seconds.rounded(toPlaces: 1))
        guard let imageForScale = CIFilter.blendWithMask(inputImage: nextImage.image,
                                                         inputMaskImage: invertedMask),
              let scaledImage = CIFilter.lanczosScaleTransform(inputImage: imageForScale,
                                                               inputScale: scaleFactor)
        else { return nil }
        
        return CIFilter.sourceOverCompositing(inputImage: scaledImage,
                                              inputBackgroundImage: currentImage.image)
    }
}

struct WithoutBackgroundSimple: Transition {
    var transitionLength: CMTimeRange = .init(start: .zero,
                                              end: .init(seconds: 0.4, preferredTimescale: 300))

    func getImage(
        for time: CMTime,
        currentImage: VideoImageItem,
        nextImage: VideoImageItem
    ) -> CIImage? {
        let currentImage = CIFilter.blendWithMask(inputImage: nextImage.image,
                                                  inputBackgroundImage: currentImage.image,
                                                  inputMaskImage: nextImage.imageFrontPlane)
        return currentImage
    }
}

struct WithoutBackgroundAndRotate: Transition {
    var transitionLength: CMTimeRange = .init(start: .zero,
                                              end: .init(seconds: 0.8, preferredTimescale: 300))
    
    let firstAnimRange: CMTimeRange = .init(start: .zero,
                                            end: .init(seconds: 0.5, preferredTimescale: 300))
    
    func getImage(
        for time: CMTime,
        currentImage: VideoImageItem,
        nextImage: VideoImageItem
    ) -> CIImage? {
        let degrees = -15.0
        let transform = CGAffineTransform(translationX: 150, y: 150)
            .rotated(by: degrees * .pi / 180)
            .translatedBy(x: 150, y: 150)
        if firstAnimRange.containsTime(time) {
            return CIFilter.blendWithMask(inputImage: nextImage.image,
                                          inputBackgroundImage: currentImage.image,
                                          inputMaskImage: nextImage.imageFrontPlane)
        } else {
            guard let invertedMask = CIFilter.colorInvert(inputImage: nextImage.imageFrontPlane),
                  let imageForRotate = CIFilter.blendWithMask(inputImage: nextImage.image,
                                                              inputMaskImage: nextImage.imageFrontPlane),
                  let rotatedImage = CIFilter.affineTransform(inputImage: imageForRotate,
                                                              inputTransform: NSValue(cgAffineTransform: transform)),
                  let background = CIFilter.blendWithMask(inputImage: nextImage.image,
                                                          inputBackgroundImage: currentImage.image,
                                                          inputMaskImage: invertedMask)
            else { return nil }

            return CIFilter.sourceOverCompositing(inputImage: rotatedImage,
                                                  inputBackgroundImage: background)
        }
    }
}

struct WithoutFrontSimple: Transition {
    var transitionLength: CMTimeRange = .init(start: .zero,
                                              end: .init(seconds: 0.4, preferredTimescale: 300))
        
    func getImage(
        for time: CMTime,
        currentImage: VideoImageItem,
        nextImage: VideoImageItem
    ) -> CIImage? {
        guard let invertedMask = CIFilter.colorInvert(inputImage: nextImage.imageFrontPlane)
        else { return nil }
        let currentImage = CIFilter.blendWithMask(inputImage: nextImage.image,
                                                  inputBackgroundImage: currentImage.image,
                                                  inputMaskImage: invertedMask)
        return currentImage
    }
}
