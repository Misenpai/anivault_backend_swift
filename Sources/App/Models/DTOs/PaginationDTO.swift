//
//  PaginationDTO.swift
//  anivault_backend
//
//  Created by Sumit Sinha on 08/11/25.
//

import Vapor

struct PaginatedResponse<T: Content>: Content {
    let data: [T]
    let pagination: PaginationMetadata
}

struct PaginationMetadata: Content {
    let page: Int
    let perPage: Int
    let totalPages: Int
    let totalCount: Int
    let hasNext: Bool
    let hasPrevious: Bool
    
    enum CodingKeys: String, CodingKey {
        case page
        case perPage = "per_page"
        case totalPages = "total_pages"
        case totalCount = "total_count"
        case hasNext = "has_next"
        case hasPrevious = "has_previous"
    }
}

struct PaginationRequest: Content {
    let page: Int
    let limit: Int

    static let defaultPage = 1
    static let defaultLimit = 25
    static let maxLimit = 100
    
    init(page: Int? = nil, limit: Int? = nil) {
        self.page = max(page ?? Self.defaultPage, 1)
        self.limit = min(max(limit ?? Self.defaultLimit, 1), Self.maxLimit)
    }
}


extension Page {
    func toPaginatedResponse<T: Content>(transform: (E) -> T) -> PaginatedResponse<T> {
        let transformedData = items.map(transform)
        
        let metadata = PaginationMetadata(
            page: metadata.page,
            perPage: metadata.per,
            totalPages: metadata.pageCount,
            totalCount: metadata.total,
            hasNext: metadata.page < metadata.pageCount,
            hasPrevious: metadata.page > 1
        )
        
        return PaginatedResponse(
            data: transformedData,
            pagination: metadata
        )
    }
    
    func toPaginatedResponse() -> PaginatedResponse<E> where E: Content {
        let metadata = PaginationMetadata(
            page: metadata.page,
            perPage: metadata.per,
            totalPages: metadata.pageCount,
            totalCount: metadata.total,
            hasNext: metadata.page < metadata.pageCount,
            hasPrevious: metadata.page > 1
        )
        
        return PaginatedResponse(
            data: items,
            pagination: metadata
        )
    }
}

struct PaginationHelper {

    static func paginate<T: Content>(
        items: [T],
        page: Int,
        perPage: Int
    ) -> PaginatedResponse<T> {
        let totalCount = items.count
        let totalPages = Int(ceil(Double(totalCount) / Double(perPage)))
        let startIndex = (page - 1) * perPage
        let endIndex = min(startIndex + perPage, totalCount)
        
        let paginatedItems = startIndex < totalCount ? Array(items[startIndex..<endIndex]) : []
        
        let metadata = PaginationMetadata(
            page: page,
            perPage: perPage,
            totalPages: totalPages,
            totalCount: totalCount,
            hasNext: page < totalPages,
            hasPrevious: page > 1
        )
        
        return PaginatedResponse(
            data: paginatedItems,
            pagination: metadata
        )
    }

    static func calculateOffset(page: Int, limit: Int) -> Int {
        return (page - 1) * limit
    }
}

struct CursorPaginationRequest: Content {
    let cursor: String?
    let limit: Int
    
    static let defaultLimit = 25
    static let maxLimit = 100
    
    init(cursor: String? = nil, limit: Int? = nil) {
        self.cursor = cursor
        self.limit = min(max(limit ?? Self.defaultLimit, 1), Self.maxLimit)
    }
}

struct CursorPaginatedResponse<T: Content>: Content {
    let data: [T]
    let nextCursor: String?
    let hasMore: Bool
    
    enum CodingKeys: String, CodingKey {
        case data
        case nextCursor = "next_cursor"
        case hasMore = "has_more"
    }
}

typealias PaginatedUsersResponse = PaginatedResponse<UserDTO>

typealias PaginatedAnimeResponse = PaginatedResponse<UserAnimeStatusDTO>

typealias PaginatedAnimeSummaryResponse = PaginatedResponse<AnimeStatusSummaryDTO>