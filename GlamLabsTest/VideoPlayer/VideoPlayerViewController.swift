//
//  VideoPlayerViewController.swift
//  GlamLabsTest
//
//  Created by Роман Анпилов on 19.03.2023.
//

import UIKit
import CoreMedia
import AVFoundation

struct VideoImageItem {
    let image: CIImage
    let imageFrontPlane: CIImage
    
    init() {
        self.init(image: .black,
                  imageFrontPlane: .black)
    }
    
    init(
        image: CIImage,
        imageFrontPlane: CIImage
    ) {
        self.image = image
        self.imageFrontPlane = imageFrontPlane
    }
}

final class VideoPlayerViewController: UIViewController {
    
    var slideImages: [SlideImage] = [] {
        willSet {
            videoMaker.slideImages = newValue
            try? videoMaker.createFilmstrip(.black,
                                            duration: 11,
                                            completion: videoMaker.storeURL())
        }
    }

    private let remover = MLBackgroundRemover()

    private lazy var playerView: UIView = {
        let view = UIView()
        self.view.addSubview(view)
        return view
    }()
    
    override func viewWillLayoutSubviews() {
        super.viewWillLayoutSubviews()
        playerView.frame = view.bounds
    }
    
    lazy var videoMaker = VideoMaker(slideImages: [], complete: { url in print(url) })
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        
        prepareImages()
    }
    
    func prepareImages() {
        let dispatchGroup = DispatchGroup()

        var array: [VideoImageItem] = .init(repeating: .init(), count: 8)

        for i in 0...7 {
            dispatchGroup.enter()
            DispatchQueue.global().async { [weak self] in
                defer { dispatchGroup.leave() }
                guard let self,
                      let currentImage = UIImage(named: "image \(i + 1)")?.resized(to: .init(width: 2000, height: 2897)),
                      let currentCIImage = CIImage(image: currentImage),
                      let frontPlane = self.remover.frontPlane(currentImage)
                else { return }
                
                array[i] = .init(image: currentCIImage, imageFrontPlane: frontPlane)
            }
        }
        
        dispatchGroup.notify(queue: .main) {
            self.makeImageSlides(images: array)
        }
    }
    
    func makeImageSlides(images: [VideoImageItem]) {
        let transitions: [any Transition] = [WithoutFrontSimple(),
                                             WithoutBackgroundSimple(),
                                             WithoutBackgroundAndRotate(),
                                             ScaleFront(),
                                             ScaleBackground()]
        var slideImages: [SlideImage] = []
        for (index, image) in images.enumerated() {
            let slideImage: SlideImage = .init(image: image,
                                               timeRange: makeTimeRange(index: index),
                                               transition: transitions[Int.random(in: 0...4)])
            slideImages.append(slideImage)
        }
        self.slideImages = slideImages
    }
    
    func makeTimeRange(index: Int) -> CMTimeRange {
        return .init(start: CMTimeMakeWithSeconds(Float64(Float(index) * (11.0/8)), preferredTimescale: 300),
                     end: CMTimeMakeWithSeconds(Float64(index + 1) * (11.0/8), preferredTimescale: 300))
    }
}
