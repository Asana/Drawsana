//
//  ShapeTransform.swift
//  Drawsana
//
//  Created by Steve Landey on 8/2/18.
//  Copyright © 2018 Asana. All rights reserved.
//

import CoreGraphics

/**
 Simplified representation of three ordered affine transforms (translate,
 rotate, scale) that can be applied to `ShapeWithTransform`.
 */
public struct ShapeTransform: Codable, Equatable {
  public var translation: CGPoint
  public var rotation: CGFloat
  public var scale: CGFloat

  public static let identity = ShapeTransform(translation: .zero, rotation: 0, scale: 1)
}

extension ShapeTransform {
  /// Returns `true` iff this shape has zero translation, zero rotation, and 1 scale
  public var isIdentity: Bool {
    return translation.x == 0 && translation.y == 0 && rotation == 0 && scale == 1
  }

  /// Representation of this transform as a `CGAffineTransform`
  public var affineTransform: CGAffineTransform {
    return CGAffineTransform(translationX: translation.x, y: translation.y)
      .rotated(by: rotation)
      .scaledBy(x: scale, y: scale)
  }

  /// Apply this transform in Core Graphics
  public func begin(context: CGContext) {
    context.saveGState()
    context.concatenate(affineTransform)
  }

  /// Unapply this transform in Core Graphics (must be paired with exactly one
  /// `begin(context:)` at the same GState nesting level!)
  public func end(context: CGContext) {
    context.restoreGState()
  }

  /// Return a copy of this transform with its translation moved by the given
  /// amount
  public func translated(by delta: CGPoint) -> ShapeTransform {
    return ShapeTransform(
      translation: CGPoint(x: translation.x + delta.x, y: translation.y + delta.y),
      rotation: rotation,
      scale: scale)
  }

  /// Return a copy of this transform with its scale multiplied by the given
  /// amount
  public func scaled(by amount: CGFloat) -> ShapeTransform {
    return ShapeTransform(
      translation: translation,
      rotation: rotation,
      scale: scale * amount)
  }

  /// Return a copy of this transform with its rotation changed by the given
  /// amount
  public func rotated(by radians: CGFloat) -> ShapeTransform {
    return ShapeTransform(
      translation: translation,
      rotation: rotation + radians,
      scale: scale)
  }
}
