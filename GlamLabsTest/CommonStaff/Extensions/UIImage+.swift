//
//  UIImage+.swift
//  GlamLabsTest
//
//  Created by Роман Анпилов on 19.03.2023.
//

import UIKit

extension UIImage {
    @nonobjc public func resized(to newSize: CGSize, scale: CGFloat = 1) -> UIImage {
      let format = UIGraphicsImageRendererFormat.default()
      format.scale = scale
      let renderer = UIGraphicsImageRenderer(size: newSize, format: format)
      let image = renderer.image { _ in
        draw(in: CGRect(origin: .zero, size: newSize))
      }
      return image
    }
    
    public func pixelBuffer(width: Int, height: Int) -> CVPixelBuffer? {
      return pixelBuffer(width: width, height: height,
                         pixelFormatType: kCVPixelFormatType_32ARGB,
                         colorSpace: CGColorSpaceCreateDeviceRGB(),
                         alphaInfo: .noneSkipFirst)
    }
    
    public func pixelBuffer(width: Int, height: Int,
                            pixelFormatType: OSType,
                            colorSpace: CGColorSpace,
                            alphaInfo: CGImageAlphaInfo) -> CVPixelBuffer? {
      var maybePixelBuffer: CVPixelBuffer?
      let attrs = [kCVPixelBufferCGImageCompatibilityKey: kCFBooleanTrue,
                   kCVPixelBufferCGBitmapContextCompatibilityKey: kCFBooleanTrue]
      let status = CVPixelBufferCreate(kCFAllocatorDefault,
                                       width,
                                       height,
                                       pixelFormatType,
                                       attrs as CFDictionary,
                                       &maybePixelBuffer)

      guard status == kCVReturnSuccess, let pixelBuffer = maybePixelBuffer else {
        return nil
      }

      let flags = CVPixelBufferLockFlags(rawValue: 0)
      guard kCVReturnSuccess == CVPixelBufferLockBaseAddress(pixelBuffer, flags) else {
        return nil
      }
      defer { CVPixelBufferUnlockBaseAddress(pixelBuffer, flags) }

      guard let context = CGContext(data: CVPixelBufferGetBaseAddress(pixelBuffer),
                                    width: width,
                                    height: height,
                                    bitsPerComponent: 8,
                                    bytesPerRow: CVPixelBufferGetBytesPerRow(pixelBuffer),
                                    space: colorSpace,
                                    bitmapInfo: alphaInfo.rawValue)
      else {
        return nil
      }

      UIGraphicsPushContext(context)
      context.translateBy(x: 0, y: CGFloat(height))
      context.scaleBy(x: 1, y: -1)
      self.draw(in: CGRect(x: 0, y: 0, width: width, height: height))
      UIGraphicsPopContext()

      return pixelBuffer
    }
}
