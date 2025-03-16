//
//  DateFormatter+Extensions.swift
//  BeRealDupe
//
//  Created by Cristobal Elizarrarz on 2/25/25.
//

import Foundation

extension DateFormatter {
    static var postFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.dateStyle = .full
        return formatter
    }()
}
