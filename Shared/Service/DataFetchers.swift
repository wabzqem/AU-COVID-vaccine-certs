//
//  DataFetchers.swift
//  AU COVID Verifier
//
//  Created by Richard Nelson on 15/9/21.
//

import Foundation
import UIKit

class QRCodeFetcher: ObservableObject {
    @Published var image: UIImage?

    func getQRCode(irn: Int) {
        let request = URLRequest(url: URL(string: "https://medicare.whatsbeef.net/?irn=\(irn)")!)
        URLSession.shared.dataTask(with: request) {(data, response, error) in
            if let data = data {
                DispatchQueue.main.async {
                    self.image = UIImage(data: data)
                }
            }
        }.resume()
    }
}

class VaccineStatusFetcher: ObservableObject {
    @Published var vaccineData: VaccineData?
    
    func getVaccineData(irn: Int) {
        let request = URLRequest(url: URL(string: "https://www2.medicareaustralia.gov.au/moaapi/moa-ihs/record/cir/data/\(irn)")!)
        URLSession.shared.dataTask(with: request) {(data, response, error) in
            if let data = data {
                DispatchQueue.main.async {
                    do {
                        self.vaccineData = try JSONDecoder().decode(VaccineData.self, from: data)
                    } catch {
                        print("Couldn't fetch vaccine status")
                    }
                }
            }
        }.resume()
    }
}
