//
//  VideoExporter.swift
//  GlamLabsTest
//
//  Created by Роман Анпилов on 19.03.2023.
//

import AVFoundation
import os

final class VideoExporter {
    func export(
        video: AVAsset,
        withPreset preset: String = AVAssetExportPresetHighestQuality,
        toFileType outputFileType: AVFileType = .mov,
        atURL outputURL: URL
    ) async {
        guard await AVAssetExportSession.compatibility(ofExportPreset: preset,
                                                       with: video,
                                                       outputFileType: outputFileType) else {
            print("The preset can't export the video to the output file type.")
            return
        }
        
        guard let exportSession = AVAssetExportSession(asset: video,
                                                       presetName: preset) else {
            print("Failed to create export session.")
            return
        }
        
        do {
            try FileManager.default.removeItem(at: outputURL)
        } catch {
            print("Could not remove file \(error.localizedDescription)")
        }
        
        exportSession.outputFileType = outputFileType
        exportSession.outputURL = outputURL
        
        await exportSession.export()
    }
    
    func export(
        _ asset: AVAsset,
        composition: AVVideoComposition,
        completion: @escaping (Result<URL, Error>) -> Void
    ) {
        let outputMovieURL = AppConstants.fileManager.appendingPathComponent("final_export.mov")

        do {
            try FileManager.default.removeItem(at: outputMovieURL)
        } catch {
            print("Could not remove file \(error.localizedDescription)")
        }

        let exporter = AVAssetExportSession(asset: asset,
                                            presetName: AVAssetExportPresetHighestQuality)

        exporter?.videoComposition = composition
        exporter?.outputURL = outputMovieURL
        exporter?.outputFileType = .mov

        exporter?.exportAsynchronously { [weak exporter] in
            DispatchQueue.main.async {
                if let error = exporter?.error {
                    completion(.failure(error))
                    Logger().error("failed \(error.localizedDescription)")
                } else {
                    completion(.success(outputMovieURL))
                    Logger().info("Movie exported: \(outputMovieURL)")
                }
            }
        }
    }
}
