import AVFoundation
import UIKit

enum WexloVideoMedia {
    static func url(
        for fileName: String,
        storage: WexloMediaStorage = .bundled
    ) -> URL? {
        if storage == .local {
            guard let url = WexloLocalContentStore.shared.mediaURL(for: fileName),
                  FileManager.default.fileExists(atPath: url.path) else {
                return nil
            }
            return url
        }

        let name = (fileName as NSString).deletingPathExtension
        let fileExtension = (fileName as NSString).pathExtension
        if !fileExtension.isEmpty,
           let url = Bundle.main.url(forResource: name, withExtension: fileExtension) {
            return url
        }
        return Bundle.main.url(forResource: fileName, withExtension: nil)
    }

    static func loadFirstFrame(
        for fileName: String,
        storage: WexloMediaStorage = .bundled,
        completion: @escaping (UIImage?) -> Void
    ) {
        guard let fileURL = url(for: fileName, storage: storage) else {
            DispatchQueue.main.async {
                completion(nil)
            }
            return
        }

        DispatchQueue.global(qos: .userInitiated).async {
            let asset = AVAsset(url: fileURL)
            let generator = AVAssetImageGenerator(asset: asset)
            generator.appliesPreferredTrackTransform = true
            let image = try? UIImage(
                cgImage: generator.copyCGImage(at: .zero, actualTime: nil)
            )

            DispatchQueue.main.async {
                completion(image)
            }
        }
    }
}
