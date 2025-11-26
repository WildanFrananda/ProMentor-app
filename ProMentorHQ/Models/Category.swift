//
//  Category.swift
//  ProMentorHQ
//
//  Created by Wildan Frananda on 25/11/25.
//

import Foundation

struct SessionCategory: Codable, Identifiable, Equatable, Hashable {
    let id: String
    let name: String
    let icon: String
}
