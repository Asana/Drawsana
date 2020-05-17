//
//  CGRect+DrawsanaExtensions.swift
//  Drawsana
//
//  Created by Steve Landey on 8/8/18.
//  Copyright © 2018 Asana. All rights reserved.
//

import CoreGraphics

extension CGRect {
  var middle: CGPoint {
    return CGPoint(x: midX, y: midY)
  }
}
