//
//  Pagination.swift
//  ProMentorHQ
//
//  Created by Wildan Frananda on 25/11/25.
//

import Foundation

struct PaginatedResponse<T: Decodable>: Decodable {
    let data: [T]
    let meta: Meta
    
    struct Meta: Decodable {
        let currentPage: Int
        let totalPages: Int
        let totalItems: Int
        let perPage: Int
    }
}
