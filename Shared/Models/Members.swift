//
//  Members.swift
//  AU COVID Verifier
//
//  Created by Richard Nelson on 14/9/21.
//

import Foundation

struct Members: Codable {
    var memberList: [Member]
}

struct Member: Hashable, Codable, Identifiable {
    var id: Int {
        get {
            return memberIRN
        }
    }
    
    var memberDisplayName: String
    var memberIRN: Int
    var claimant: Bool
}
