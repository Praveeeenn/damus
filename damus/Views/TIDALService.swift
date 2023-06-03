//
//  TIDALService.swift
//  damus
//
//  Created by Praveen Rajput on 26/05/23.
//

import Foundation

struct ManifestService {
    
    enum URLType {
        case track(String)
        case album(String)
        case playlist(String)
        case invalid
        
        init(urlString: String) {
            let regexPattern = "^(https?://)?(www\\.)?tidal\\.com/(browse/)?(track|album|playlist)/([0-9a-fA-F\\-]+)$"
            
            if let regex = try? NSRegularExpression(pattern: regexPattern),
                let match = regex.firstMatch(in: urlString, range: NSRange(location: 0, length: urlString.count)),
                let range = Range(match.range(at: 4), in: urlString),
                let valueRange = Range(match.range(at: 5), in: urlString) {
                
                let type = String(urlString[range])
                let value = String(urlString[valueRange])
                
                switch type {
                case "track":
                    self = .track(value)
                case "album":
                    self = .album(value)
                case "playlist":
                    self = .playlist(value)
                default:
                    self = .invalid
                }
            } else {
                self = .invalid
            }
        }
    }

    
    //let shared = ManifestService()
    
    private func fetchManifestJSON(trackId: Int) async throws -> String {
        
        let urlString = "https://api.tidal.com/v1/tracks/\(trackId)/playbackinfoprepaywall/v4?assetpresentation=PREVIEW&audioquality=LOW"
        let headers = [
            "X-Tidal-Token": "S0wuxKXcRQLsoQ6R"
        ]
        
        var request = URLRequest(url: URL(string: urlString)!)
        request.allHTTPHeaderFields = headers
        
        let (data, _) = try await URLSession.shared.data(for: request)
        
        guard let jsonString = String(data: data, encoding: .utf8) else {
            throw NSError(domain: "", code: 0, userInfo: nil) // Update with appropriate error
        }
        
        return jsonString
    }
    
    private func extractURLs(from jsonString: String) -> [String]? {
        struct Manifest: Codable {
            let urls: [String]
        }
        
        guard let jsonData = jsonString.data(using: .utf8),
              let jsonObject = try? JSONSerialization.jsonObject(with: jsonData, options: []) as? [String: AnyObject],
              let manifestBase64 = jsonObject["manifest"] as? String,
              let manifestData = Data(base64Encoded: manifestBase64),
              let manifest = try? JSONDecoder().decode(Manifest.self, from: manifestData) else {
            // Error handling if JSON parsing or decoding fails
            return nil
        }
        
        return manifest.urls
    }
    
    func getPreviewURL(urlString: String) async throws -> URL? {
        
        let urlType = URLType(urlString: urlString) //URLType(urlString: "https://tidal.com/track/82033139")

        switch urlType {
        case .track(let value):
            print("Track: \(value)")
            let jsonString = try await fetchManifestJSON(trackId: Int(value)!)

            guard
                let urls = extractURLs(from: jsonString),
                let firstURL = urls.first,
                let url = URL(string: firstURL)
            else {
                throw NSError(domain: "", code: 0, userInfo: nil) // Update with appropriate error
            }
            return url
        case .album(let value):
            print("Album: \(value)")
            return nil
        case .playlist(let value):
            print("Playlist: \(value)")
            return nil
        case .invalid:
            print("Invalid URL")
            return nil
        }
    }
}
