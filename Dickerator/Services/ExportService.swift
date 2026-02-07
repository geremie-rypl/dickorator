import UIKit
import Photos

class ExportService {
    static let shared = ExportService()

    private init() {}

    struct ExportResult {
        let cleanImage: UIImage
        let censoredImage: UIImage
    }

    // MARK: - Image Compositing

    func flattenLayers(
        baseImage: UIImage,
        filterOverlay: UIImage?,
        stickers: [(image: UIImage, transform: CGAffineTransform)]
    ) -> UIImage {
        let size = baseImage.size
        let renderer = UIGraphicsImageRenderer(size: size)

        return renderer.image { context in
            // Layer 1: Base photo
            baseImage.draw(at: .zero)

            // Layer 2: Filter overlay (full frame)
            if let overlay = filterOverlay {
                overlay.draw(in: CGRect(origin: .zero, size: size))
            }

            // Layer 3: Stickers
            for sticker in stickers {
                context.cgContext.saveGState()
                context.cgContext.concatenate(sticker.transform)
                sticker.image.draw(at: .zero)
                context.cgContext.restoreGState()
            }
        }
    }

    func createExportImages(
        baseImage: UIImage,
        filterOverlay: UIImage?,
        stickers: [(image: UIImage, transform: CGAffineTransform)]
    ) -> ExportResult {
        let cleanImage = flattenLayers(
            baseImage: baseImage,
            filterOverlay: filterOverlay,
            stickers: stickers
        )

        let censoredImage = applyCensoring(to: cleanImage)

        return ExportResult(cleanImage: cleanImage, censoredImage: censoredImage)
    }

    // MARK: - Censoring

    private func applyCensoring(to image: UIImage) -> UIImage {
        let size = image.size
        let renderer = UIGraphicsImageRenderer(size: size)

        return renderer.image { context in
            // Draw original
            image.draw(at: .zero)

            // Apply center blur
            let blurRect = CGRect(
                x: size.width * 0.25,
                y: size.height * 0.25,
                width: size.width * 0.5,
                height: size.height * 0.5
            )

            if let blurredCenter = createBlurredRegion(from: image, rect: blurRect) {
                blurredCenter.draw(in: blurRect)
            }

            // Add watermark
            drawWatermark(in: context.cgContext, size: size)
        }
    }

    private func createBlurredRegion(from image: UIImage, rect: CGRect) -> UIImage? {
        guard let cgImage = image.cgImage,
              let cropped = cgImage.cropping(to: rect) else {
            return nil
        }

        let ciImage = CIImage(cgImage: cropped)
        let filter = CIFilter(name: "CIGaussianBlur")
        filter?.setValue(ciImage, forKey: kCIInputImageKey)
        filter?.setValue(20.0, forKey: kCIInputRadiusKey)

        guard let output = filter?.outputImage else { return nil }

        let context = CIContext()
        guard let blurredCG = context.createCGImage(output, from: ciImage.extent) else {
            return nil
        }

        return UIImage(cgImage: blurredCG)
    }

    private func drawWatermark(in context: CGContext, size: CGSize) {
        let text = "Made with Dickerator"
        let attributes: [NSAttributedString.Key: Any] = [
            .font: UIFont.systemFont(ofSize: 14, weight: .medium),
            .foregroundColor: UIColor.white.withAlphaComponent(0.7)
        ]

        let textSize = text.size(withAttributes: attributes)
        let point = CGPoint(
            x: size.width - textSize.width - 10,
            y: size.height - textSize.height - 10
        )

        (text as NSString).draw(at: point, withAttributes: attributes)
    }

    // MARK: - Save & Share

    func saveToPhotoLibrary(_ image: UIImage) async throws {
        try await PHPhotoLibrary.shared().performChanges {
            PHAssetChangeRequest.creationRequestForAsset(from: image)
        }
    }

    func shareImage(_ image: UIImage, from viewController: UIViewController) {
        let activityVC = UIActivityViewController(
            activityItems: [image],
            applicationActivities: nil
        )
        viewController.present(activityVC, animated: true)
    }

    func imageData(_ image: UIImage, quality: CGFloat = 0.9) -> Data? {
        image.jpegData(compressionQuality: quality)
    }
}
