//
//  CertView.swift
//  AU COVID Verifier
//
//  Created by Richard Nelson on 14/9/21.
//

import SwiftUI
import Combine

struct CertView: View {
    var member: Member
    @StateObject var imageFetcher = QRCodeFetcher()
    @StateObject var dataFetcher = VaccineStatusFetcher()
    
    var vaccineDetail: String {
        return "Valid From \(dataFetcher.vaccineData?.immunisationRecordData.immunisationStatus.vaccineInfo.last?.immunisationDate ?? "Loading...")"
    }
    
    var body: some View {
        VStack {
            if (dataFetcher.vaccineData != nil) {
                VStack {
                    HStack {
                        Text(member.memberDisplayName).font(.title2).padding()
                        Text("DOB: \(dataFetcher.vaccineData?.immunisationRecordData.individualDetails.dateOfBirth ?? "")").font(.title2).padding()
                    }
                    Text("Last vaccine: \(dataFetcher.vaccineData?.immunisationRecordData.immunisationStatus.vaccineInfo.last?.vaccineBrand ?? "")").padding()
                }.navigationTitle("COVID-19 Certificate").padding()
                Image(uiImage: imageFetcher.image ?? UIImage())
                    .resizable()
                    .scaledToFit().padding()
                Text(vaccineDetail)
                Spacer(minLength: 100)
            } else if let error = dataFetcher.errorMessage {
                Text(error)
            } else {
                Text("Loading...")
            }
        }.onAppear {
            if (imageFetcher.image == nil) {
                imageFetcher.getQRCode(irn: member.memberIRN, completion: nil)
                dataFetcher.getVaccineData(irn: member.memberIRN)
            }
        }.toolbar {
            HStack {
                Text("")
                NavigationLink(destination: PDFViewM(irn: member.memberIRN)) {
                    Text("PDF")
                }
            }
        }
    }
}

struct CertView_Previews: PreviewProvider {
    static var previews: some View {
        CertView(member: Member(memberDisplayName: "RICHARD A NELSON", memberIRN: 1, claimant: true))
    }
}
