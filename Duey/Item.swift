//
//  Item.swift
//  Duey
//
//  Created by Xiao Xiao on 2025/10/19.
//

import Foundation
import SwiftData

@Model
final class Item {
    var timestamp: Date
    
    init(timestamp: Date) {
        self.timestamp = timestamp
    }
}
