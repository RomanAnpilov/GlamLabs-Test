//
//  CIImage+.swift
//  GlamLabsTest
//
//  Created by Роман Анпилов on 19.03.2023.
//

import CoreImage

extension CIImage {
    func applyBlurEffect() -> CIImage? {
        let context = CIContext(options: nil)
        let clampFilter = CIFilter(name: "CIAffineClamp")!
        clampFilter.setDefaults()
        clampFilter.setValue(self, forKey: kCIInputImageKey)

        guard let currentFilter = CIFilter(name: "CIGaussianBlur")
        else { return nil }
        
        currentFilter.setValue(clampFilter.outputImage, forKey: kCIInputImageKey)
        currentFilter.setValue(2, forKey: "inputRadius")
        
        guard let output = currentFilter.outputImage,
              let cgimg = context.createCGImage(output, from: extent)
        else { return nil }

        return CIImage(cgImage: cgimg)
    }
}
