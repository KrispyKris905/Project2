//
//  Post.swift
//  BeRealDupe
//
//  Created by Cristobal Elizarrarz on 2/25/25.
//

import Foundation

// TODO: Pt 1 - Import Parse Swift
import ParseSwift

// TODO: Pt 1 - Create Post Parse Object model
// https://github.com/parse-community/Parse-Swift/blob/3d4bb13acd7496a49b259e541928ad493219d363/ParseSwift.playground/Pages/1%20-%20Your%20first%20Object.xcplaygroundpage/Contents.swift#L33

struct Post: ParseObject {
    // These are required by ParseObject
    var objectId: String?
    var createdAt: Date?
    var updatedAt: Date?
    var ACL: ParseACL?
    var originalData: Data?

    // Your own custom properties.
    var locationCity: String?
    var locationCountry: String?
    var caption: String?
    var user: User?
    var postUser: String?
    var imageFile: ParseFile?
    mutating func set(_ city: String, _ country: String) {
        self.locationCity=city
        self.locationCountry=country
    }
}
