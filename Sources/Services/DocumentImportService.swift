import Foundation
import PDFKit
import Vision
import ImageIO
import UIKit

struct ImportedStudySource {
    let text: String
    let name: String
    let type: String
    let warning: String?
}

enum DocumentImportError: LocalizedError {
    case unreadablePDF
    case emptyDocument
    case unsupportedImage

    var errorDescription: String? {
        switch self {
        case .unreadablePDF:
            "Could not read this PDF. It may be protected or unsupported."
        case .emptyDocument:
            "No text was found. Try a clearer image or paste the text."
        case .unsupportedImage:
            "Could not read the selected image."
        }
    }
}

enum DocumentImportService {
    static func readPDF(at url: URL) throws -> ImportedStudySource {
        let hasAccess = url.startAccessingSecurityScopedResource()
        defer {
            if hasAccess { url.stopAccessingSecurityScopedResource() }
        }

        guard let document = PDFDocument(url: url) else {
            throw DocumentImportError.unreadablePDF
        }

        var pages: [String] = []
        var pagesWithoutText = 0

        for index in 0..<document.pageCount {
            guard let page = document.page(at: index) else { continue }
            var text = page.string?.trimmingCharacters(in: .whitespacesAndNewlines) ?? ""

            if text.isEmpty {
                let thumbnail = page.thumbnail(
                    of: CGSize(width: 1600, height: 2200),
                    for: .mediaBox
                )
                if let cgImage = thumbnail.cgImage,
                   let recognized = try? recognizeText(in: cgImage) {
                    text = recognized
                }
            }

            if text.isEmpty {
                pagesWithoutText += 1
            } else {
                pages.append("[Page \(index + 1)]\n\(text)")
            }
        }

        let joined = pages.joined(separator: "\n\n")
        guard !joined.isEmpty else { throw DocumentImportError.emptyDocument }

        let warning = pagesWithoutText > 0
            ? "\(pagesWithoutText) page(s) could not be extracted. Review the source before generating study material."
            : nil

        return ImportedStudySource(
            text: joined,
            name: url.lastPathComponent,
            type: "PDF",
            warning: warning
        )
    }

    static func readImage(data: Data, name: String) throws -> ImportedStudySource {
        guard let source = CGImageSourceCreateWithData(data as CFData, nil),
              let image = CGImageSourceCreateImageAtIndex(source, 0, nil) else {
            throw DocumentImportError.unsupportedImage
        }

        let text = try recognizeText(in: image)
        guard !text.isEmpty else { throw DocumentImportError.emptyDocument }

        return ImportedStudySource(
            text: text,
            name: name,
            type: "Image",
            warning: "Text was extracted using OCR. Review possible recognition errors."
        )
    }

    private static func recognizeText(in image: CGImage) throws -> String {
        let request = VNRecognizeTextRequest()
        request.recognitionLevel = .accurate
        request.usesLanguageCorrection = true

        try VNImageRequestHandler(cgImage: image).perform([request])

        return (request.results ?? [])
            .sorted { $0.boundingBox.midY > $1.boundingBox.midY }
            .compactMap { $0.topCandidates(1).first?.string }
            .joined(separator: "\n")
            .trimmingCharacters(in: .whitespacesAndNewlines)
    }
}
