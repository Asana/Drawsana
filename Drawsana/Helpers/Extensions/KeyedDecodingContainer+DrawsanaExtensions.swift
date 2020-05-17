//
//  KeyedDecodingContainer+DrawsanaExtensions.swift
//  Drawsana
//
//  Created by Steve Landey on 8/8/18.
//  Copyright © 2018 Asana. All rights reserved.
//

import UIKit

extension KeyedDecodingContainer {
  func decodeColorIfPresent(forKey key: K) throws -> UIColor? {
    guard let hexString = try decodeIfPresent(String.self, forKey: key) else { return nil }
    return UIColor(hexString: hexString)
  }
}
