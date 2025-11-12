//
//  JikanService.swift
//  anivault_backend
//
//  Created by Sumit Sinha on 09/11/25.
//

import Vapor

final class JikanService {
    private let client: Client
    private let baseURL = "https://api.jikan.moe/v4"
    
    init(client: Client) {
        self.client = client
    }
    
    func getAnimeById(_ id: Int) async throws -> AnimeResponse {
        let uri = URI(string: "\(baseURL)/anime/\id)/full")
        let response = try await client.get(uri)
        return try response.content.decode(AnimeResponse.self)
    }
    
    func searchAnime(query: String, page: Int, limit: Int) async throws -> SeasonAnimeResponse {
        let uri = URI(string: "\(baseURL)/anime?q=\(query)&page=\(page)&limit=\(limit)")
        let response = try await client.get(uri)
        return try response.content.decode(SeasonAnimeResponse.self)
    }
    
    func getCurrentSeasonAnime(page: Int, limit: Int) async throws -> SeasonAnimeResponse {
        let uri = URI(string: "\(baseURL)/seasons/now?page=\(page)&limit=\(limit)")
        let response = try await client.get(uri)
        return try response.content.decode(SeasonAnimeResponse.self)
    }
    
    func getUpcomingSeasonAnime(page: Int, limit: Int) async throws -> SeasonAnimeResponse {
        let uri = URI(string: "\(baseURL)/seasons/upcoming?page=\(page)&limit=\(limit)")
        let response = try await client.get(uri)
        return try response.content.decode(SeasonAnimeResponse.self)
    }
    
    func getSeasonAnime(year: Int, season: String, page: Int) async throws -> SeasonAnimeResponse {
        let uri = URI(string: "\(baseURL)/seasons/\(year)/\(season)?page=\(page)")
        let response = try await client.get(uri)
        return try response.content.decode(SeasonAnimeResponse.self)
    }
    
    func getTopAnime(page: Int, limit: Int) async throws -> SeasonAnimeResponse {
        let uri = URI(string: "\(baseURL)/top/anime?page=\(page)&limit=\(limit)")
        let response = try await client.get(uri)
        return try response.content.decode(SeasonAnimeResponse.self)
    }
}