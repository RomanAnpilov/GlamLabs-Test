//
//  VideoMaker.swift
//  GlamLabsTest
//
//  Created by Роман Анпилов on 19.03.2023.
//

import AVFoundation
import CoreImage
import CoreImage.CIFilterBuiltins
import os
import UIKit.UIImage

struct SlideImage {
    let image: VideoImageItem
    let timeRange: CMTimeRange
    let transition: Transition
}

final class VideoMaker {
    
    var slideImages: [SlideImage] = []
    private let videoExporter = VideoExporter()
    
    var complete: (URL) -> ()
    
    init(slideImages: [SlideImage], complete: @escaping (URL) -> Void) {
        self.slideImages = slideImages
        self.complete = complete
    }
    
    func getSlideImage(for time: CMTime) -> SlideImage? {
        return slideImages.first { $0.timeRange.containsTime(time) }
    }
    
    func createComposition(_ asset: AVAsset) {
        let slideshowComposition = AVVideoComposition(asset: asset) { [weak self] request in
            let compositionTime = request.compositionTime
            
            guard let self = self,
                  let slide = self.getSlideImage(for: compositionTime)
            else { request.finish(with: .black, context: nil); return }
            
            let compose = CIFilter.sourceOverCompositing()
            compose.backgroundImage = request.sourceImage
            if slide.timeRange.end - compositionTime < slide.transition.transitionLength.duration,
               let nextSlide = self.getSlideImage(for: .init(seconds: slide.timeRange.end.seconds + 0.001,
                                                             preferredTimescale: 300)) {
                compose.inputImage = slide.transition.getImage(
                    for: slide.timeRange.end - compositionTime,
                    currentImage: slide.image,
                    nextImage: nextSlide.image
                )
            } else {
                compose.inputImage = slide.image.image
            }
            
            guard let ouputImage = compose.outputImage else { request.finish(with: .black, context: nil); return }
            request.finish(with: ouputImage, context: nil)
        }
        
        videoExporter.export(outputMovie!, composition: slideshowComposition) { [weak self] result in
            guard let audioURL = Bundle.main.url(forResource: "music", withExtension: "aac")
            else { fatalError("not audio url") }
            switch result {
            case .success(let success):
                guard let self,
                      let videoWithMusic = self.generateWithMusic(video: success,
                                                                  audio: audioURL)
                else { return }
                Task {
                    let finalURL = AppConstants.fileManager.appendingPathComponent("final.mov")
                    await self.videoExporter.export(video: videoWithMusic,
                                                    atURL: finalURL)
                    self.complete(finalURL)
                }
            case .failure:
                break
            }
        }
    }
    
    func createFilmstrip(
        _ bgColor: CIColor,
        duration: Int,
        completion: @escaping (URL)->Void
    ) throws  {
        let staticImage = CIImage(color: bgColor)
            .cropped(to: .init(x: 0, y: 0, width: 2000, height: 2897))

        var pixelBuffer: CVPixelBuffer?
        let attrs = [kCVPixelBufferCGImageCompatibilityKey: kCFBooleanTrue,
                    kCVPixelBufferCGBitmapContextCompatibilityKey: kCFBooleanTrue] as CFDictionary
        let width:Int = Int(staticImage.extent.size.width)
        let height:Int = Int(staticImage.extent.size.height)
        CVPixelBufferCreate(kCFAllocatorDefault,
                            width,
                            height,
                            kCVPixelFormatType_32BGRA,
                            attrs,
                            &pixelBuffer)

        let context = CIContext()
        context.render(staticImage, to: pixelBuffer!)

        let outputMovieURL = AppConstants.fileManager.appendingPathComponent("background.mov")

        do {
            try FileManager.default.removeItem(at: outputMovieURL)
        } catch {
            print("Could not remove file \(error.localizedDescription)")
        }

        guard let assetwriter = try? AVAssetWriter(outputURL: outputMovieURL,
                                                   fileType: .mov)
        else { fatalError("Not asset writer :(") }

        let videoSettings: [String: Any] = [AVVideoCodecKey: AVVideoCodecType.h264,
                                            AVVideoWidthKey: 2000,
                                            AVVideoHeightKey: 2897]

        let assetWriterInput = AVAssetWriterInput(mediaType: .video, outputSettings: videoSettings)

        let assetWriterAdaptor = AVAssetWriterInputPixelBufferAdaptor(assetWriterInput: assetWriterInput,
                                                                    sourcePixelBufferAttributes: nil)

        assetwriter.add(assetWriterInput)

        assetwriter.startWriting()
        assetwriter.startSession(atSourceTime: .zero)

        let framesPerSecond = 30
        let totalFrames = duration * framesPerSecond
        var frameCount = 0

        while frameCount < totalFrames {
            if assetWriterInput.isReadyForMoreMediaData {
                let frameTime = CMTimeMake(value: Int64(frameCount),
                                           timescale: Int32(framesPerSecond))
                assetWriterAdaptor.append(pixelBuffer!, withPresentationTime: frameTime)
                frameCount+=1
            }
          }

        assetWriterInput.markAsFinished()
        assetwriter.finishWriting {
            pixelBuffer = nil
            completion(outputMovieURL)
            Logger().info("Finished video location: \(outputMovieURL)")
        }
    }
    
    func generateWithMusic(video: URL, audio: URL) -> AVAsset? {
        let composition = AVMutableComposition()
        guard let videoTrack = composition.addMutableTrack(withMediaType: .video,
                                                           preferredTrackID: kCMPersistentTrackID_Invalid),
              let audioTrack = composition.addMutableTrack(withMediaType: .audio,
                                                           preferredTrackID: kCMPersistentTrackID_Invalid)
        else { return nil }
        
        let videoAsset = AVAsset(url: video)
        guard let assetVideoTrack = videoAsset.tracks(withMediaType: .video).first
        else { return nil }
        let videoAssetTimeRange = CMTimeRange(start: .zero, duration: videoAsset.duration)
        try? videoTrack.insertTimeRange(videoAssetTimeRange,
                                        of: assetVideoTrack,
                                        at: videoTrack.timeRange.duration)
        let audioAsset = AVAsset(url: audio)
        guard let assetAudioTrack = audioAsset.tracks(withMediaType: .audio).first
        else { return nil }
        let audioAssetTimeRange = CMTimeRange(start: .zero, duration: audioAsset.duration)
        try? audioTrack.insertTimeRange(audioAssetTimeRange,
                                        of: assetAudioTrack,
                                        at: audioTrack.timeRange.duration)
        
        return composition
    }
    
    var outputMovie: AVAsset? {
      didSet {
        if let outputMovie = outputMovie {
          self.createComposition(outputMovie)
        }
      }
    }
    
    func storeURL() -> (URL) -> Void {
        return { [weak self] url in
          let asset = AVAsset(url: url)
          self?.outputMovie = asset
        }
    }
}
