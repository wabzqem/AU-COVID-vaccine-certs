//
//  File.swift
//  AU COVID Verifier
//
//  Created by Richard Nelson on 15/9/21.
//

import Foundation

struct VaccineData: Codable {
    var immunisationRecordData: ImmunisationRecordData
}

struct ImmunisationRecordData: Codable {
    var individualDetails: IndividualDetails
    var immunisationStatus: ImmunisationStatus
}

struct IndividualDetails: Codable {
    var firstName: String
    var lastName: String
    var dateOfBirth: String
    var initial: String
    var ihi: String
}

struct ImmunisationStatus: Codable {
    var vaccineInfo: [VaccineInfo]
}

struct VaccineInfo: Codable {
    var vaccineBrand: String
    var immunisationDate: String
}
