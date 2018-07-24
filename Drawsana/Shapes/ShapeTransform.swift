//
//  ShapeTransform.swift
//  Drawsana
//
//  Created by Steve Landey on 8/2/18.
//  Copyright © 2018 Asana. All rights reserved.
//

import CoreGraphics

public struct ShapeTransform {
  var translation: CGPoint
  var rotation: CGFloat
  var scale: CGFloat

  static let identity = ShapeTransform(translation: .zero, rotation: 0, scale: 1)
}

extension ShapeTransform {
  public var affineTransform: CGAffineTransform {
    return CGAffineTransform(translationX: translation.x, y: translation.y).rotated(by: rotation).scaledBy(x: scale, y: scale)
  }
  public func begin(context: CGContext) {
    context.saveGState()
    context.concatenate(affineTransform)
  }

  public func end(context: CGContext) {
    context.restoreGState()
  }

  public func translated(by delta: CGPoint) -> ShapeTransform {
    return ShapeTransform(
      translation: CGPoint(x: translation.x + delta.x, y: translation.y + delta.y),
      rotation: rotation,
      scale: scale)
  }
}
