//
//  MLBackgroundRemover.swift
//  GlamLabsTest
//
//  Created by Роман Анпилов on 19.03.2023.
//

import UIKit
import CoreML

final class MLBackgroundRemover {
    private let model: segmentation_8bit
    
    init() {
        do {
            model = try segmentation_8bit()
        } catch {
            fatalError(error.localizedDescription)
        }
    }
    
    func frontPlane(_ image: UIImage) -> CIImage? {
        guard let pixelBuffer = image.pixelBuffer(width: 1024, height: 1024) else { return nil }
        do {
            let modelOutput = try model.prediction(img: pixelBuffer)
            guard let maskImage = modelOutput.var_2274.makeImage()?.resized(to: image.size).cgImage
            else { return nil }
        
            return .init(cgImage: maskImage)
        } catch {
            fatalError(error.localizedDescription)
        }
    }

}
