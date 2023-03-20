//
//  CVPixelBuffer+.swift
//  GlamLabsTest
//
//  Created by Роман Анпилов on 19.03.2023.
//

import UIKit
import VideoToolbox

extension CVPixelBuffer {
    func makeImage() -> UIImage? {
        var cgImage: CGImage?
        VTCreateCGImageFromCVPixelBuffer(self,
                                         options: nil,
                                         imageOut: &cgImage)
        guard let cgImage else { return nil }
        return UIImage(cgImage: cgImage)
    }
}
