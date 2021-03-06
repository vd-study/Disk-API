//
//  DiskFile.swift
//  yandexdisk
//
//  Created by Vlad on 30/07/2019.
//  Copyright © 2019 Anatoly. All rights reserved.
//

import Foundation

struct DiskResponse: Decodable {
    let items: [DiskFile]?
    let limit: Int64
    let offset: Int64
    
    static func parseDiskResponse(data: Data) -> DiskResponse? {
        var diskResponse: DiskResponse?
        let decoder = JSONDecoder()
        do {
            diskResponse = try decoder.decode(DiskResponse.self, from: data)
        } catch {
            print("Error while parsing DiskResponse")
        }
        return diskResponse
    }
}

struct DiskFile: Decodable {
    let name: String
    let preview: String?
    let size: Int64
}
