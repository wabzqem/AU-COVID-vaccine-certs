//
//  PDFView.swift
//  AU COVID Cert
//
//  Created by Richard Nelson on 20/9/21.
//

import SwiftUI
import PDFKit
import Combine

struct PDFViewM: View {
    var irn: Int
    @State var data : Data?
    @State var pdfView = PDFView()
        
    var body: some View {
        VStack {
            if let data = data {
                PDFViewUI(pdfView: $pdfView, data: data, singlePage: true)
            }
        }.onAppear() {
            DispatchQueue.init(label: "bgData").async {
                self.data = try? Data(contentsOf: URL(string: "https://medicare.whatsbeef.net/pdf?irn=\(irn)")!)
            }
        }.toolbar {
            Button(action: shareButton) {
                Image(systemName: "square.and.arrow.up")
            }
        }
    }
    func shareButton() {
        if let pdfData = $pdfView.wrappedValue.document?.dataRepresentation() {
            let objectsToShare = [pdfData]
            let activityVC = UIActivityViewController(activityItems: objectsToShare, applicationActivities: nil)
            activityVC.popoverPresentationController?.sourceView = pdfView
            UIApplication.shared.windows.first?.rootViewController?.present(activityVC, animated: true, completion: nil)
        }
    }
}

extension PDFDocument {
    func addImage(_ image: UIImage) {
        guard let page = page(at: 0) else { return }
        let box = page.bounds(for: .mediaBox)
        let area = CGRect(x: box.midX - 70, y: 15, width: 140, height: 140)
        let imageAnnotation = MyImageAnnotation(bounds: area, image: image)
        page.addAnnotation(imageAnnotation)
    }
}

class MyImageAnnotation: PDFAnnotation {
    var image: UIImage

    required init?(coder: NSCoder) { fatalError("coder not supported") }

    init(bounds: CGRect, image: UIImage) {
        self.image = image
        super.init(bounds: bounds, forType: .stamp, withProperties: nil)
    }

    override func draw(with box: PDFDisplayBox, in context: CGContext) {
        super.draw(with: box, in: context)
        guard let cgImage = image.cgImage else { return }

        UIGraphicsPushContext(context)
        context.saveGState()

        // Drawing code goes here
        context.draw(cgImage, in: bounds)

        context.restoreGState()
        UIGraphicsPopContext()
    }
}

/*struct PDFView_Previews: PreviewProvider {
    @State var pdfDocument: PDFDocument?
    static var previews: some View {
        PDFViewM(irn: 4, pdfDocument: $pdfDocument)
    }
}*/

struct PDFViewUI: UIViewRepresentable {
    typealias UIViewType = PDFView

    @Binding var pdfView: PDFView
    let data: Data
    let singlePage: Bool
    
    func makeUIView(context _: UIViewRepresentableContext<PDFViewUI>) -> UIViewType {
        $pdfView.wrappedValue.document = PDFDocument(data: data)
        if singlePage {
            pdfView.displayMode = .singlePage
        }
        pdfView.autoScales = true
        QRCodeFetcher().getQRCode(irn: 4) { image in
            pdfView.document?.addImage(image)
        }
        return pdfView
    }

    func updateUIView(_ pdfView: UIViewType, context _: UIViewRepresentableContext<PDFViewUI>) {
        pdfView.document = PDFDocument(data: data)
    }
}
