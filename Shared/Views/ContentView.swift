//
//  ContentView.swift
//  Shared
//
//  Created by Richard Nelson on 12/9/21.
//

import SwiftUI
import UIKit
import WebKit
import Combine

struct ContentView: View {
    @State private var isPresented = true {
        didSet {
            if !isPresented && members.count == 0 {
                fetchMembers()
            }
        }
    }
    @State var members: [Member]
    var body: some View {
        NavigationView {
            VStack {
                List(members) { member in
                    NavigationLink(destination: CertView(member: member)) {
                        Text("\(member.memberDisplayName) (\(member.memberIRN))")
                            .padding()
                    }
                }
            }
            .navigationTitle("Members")
            .toolbar {
                Button("Logout") {
                    WKWebView.init().configuration.websiteDataStore.removeData(ofTypes: WKWebsiteDataStore.allWebsiteDataTypes(), modifiedSince: Date(timeIntervalSince1970: 0)) {}
                    HTTPCookieStorage.shared.removeCookies(since: Date(timeIntervalSince1970: 0))
                    UserDefaults.standard.removeObject(forKey: "access_token")
                    UserDefaults.standard.removeObject(forKey: "refresh_token")
                    members = []
                }
            }
        }
        .sheet(isPresented: $isPresented) {
            SAWebView {
                isPresented = false
            }
        }
    }
    
    private func fetchMembers() {
        let request = URLRequest(url: URL(string: "https://www2.medicareaustralia.gov.au/moaapi/moa-ihs/member-list")!)
        URLSession.shared.dataTask(with: request) {(data, response, error) in
            if let data = data {
                do {
                    let members = try JSONDecoder().decode(Members.self, from: data)
                    self.members = members.memberList
                } catch {
                    print("Couldn't fetch member list: \(String(describing: String(data: data, encoding: .utf8)))")
                }
            }
        }.resume()
    }
}

struct ContentView_Previews: PreviewProvider {
    static var previews: some View {
        ContentView(members: [Member(memberDisplayName: "RICHARD A NELSON", memberIRN: 4, claimant: true)])
    }
}
