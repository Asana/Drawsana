//
//  AMShape.swift
//  AMDrawingView
//
//  Created by Steve Landey on 7/23/18.
//  Copyright © 2018 Asana. All rights reserved.
//

import UIKit

/**
 Base protocol which all shapes must implement.

 Note: If you implement your own shapes, see `Drawing.shapeDecoder`!
 */
public protocol Shape: AnyObject, Codable {
  /// Globally unique identifier for this shape. Meant to be used for equality
  /// checks, especially for network-based updates.
  var id: String { get set }

  /// String value of this shape, for serialization and debugging
  static var type: String { get }

  /// Draw this shape to the given Core Graphics context. Transforms for drawing
  /// position and scale are already applied.
  func render(in context: CGContext)

  /// Return true iff the given point meaningfully intersects with the pixels
  /// drawn by this shape. See `ShapeWithBoundingRect` for a shortcut.
  func hitTest(point: CGPoint) -> Bool

  /// Apply any relevant values in `userSettings` (colors, sizes, fonts...) to
  /// this shape
  func apply(userSettings: UserSettings)
}

/**
 Enhancement to `Shape` protocol that allows you to simply specify a
 `boundingRect` property and have `hitTest` implemented automatically.
 */
public protocol ShapeWithBoundingRect: Shape {
  var boundingRect: CGRect { get }
}

extension ShapeWithBoundingRect {
  public func hitTest(point: CGPoint) -> Bool {
    return boundingRect.contains(point)
  }
}

/**
 Enhancement to `Shape` protocol that has a `transform` property, meaning it can
 be translated, rotated, and scaled relative to its original characteristics.
 */
public protocol ShapeWithTransform: Shape {
  var transform: ShapeTransform { get set }
}

/**
 Enhancement to `Shape` protocol that enforces requirements necessary for a
 shape to be used with the selection tool. This includes
 `ShapeWithBoundingRect` to render the selection rect around the shape, and
 `ShapeWithTransform` to allow the shape to be moved from its original
 position
 */
public protocol ShapeSelectable: ShapeWithBoundingRect, ShapeWithTransform {
}

extension ShapeSelectable {
  public func hitTest(point: CGPoint) -> Bool {
    return boundingRect.applying(transform.affineTransform).contains(point)
  }
}

/**
 Enhancement to `Shape` adding properties to match all `UserSettings`
 properties. There is a convenience method `apply(userSettings:)` which updates
 the shape to match the given values.
 */
public protocol ShapeWithStandardState: AnyObject {
  var strokeColor: UIColor? { get set }
  var fillColor: UIColor? { get set }
  var strokeWidth: CGFloat { get set }
}

extension ShapeWithStandardState {
  public func apply(userSettings: UserSettings) {
    strokeColor = userSettings.strokeColor
    fillColor = userSettings.fillColor
    strokeWidth = userSettings.strokeWidth
  }
}

/**
 Like `ShapeWithStandardState`, but ignores `UserSettings.fillColor`.
 */
public protocol ShapeWithStrokeState: AnyObject {
  var strokeColor: UIColor { get set }
  var strokeWidth: CGFloat { get set }
}

extension ShapeWithStrokeState {
  public func apply(userSettings: UserSettings) {
    strokeColor = userSettings.strokeColor ?? .black
    strokeWidth = userSettings.strokeWidth
  }
}

/**
 Special case of `Shape` where the shape is defined by exactly two points.
 This case is used to share code between the line, ellipse, and rectangle shapes
 and tools.
 */
public protocol ShapeWithTwoPoints {
  var a: CGPoint { get set }
  var b: CGPoint { get set }

  var strokeWidth: CGFloat { get set }
}

extension ShapeWithTwoPoints {
  public var rect: CGRect {
    let x1 = min(a.x, b.x)
    let y1 = min(a.y, b.y)
    let x2 = max(a.x, b.x)
    let y2 = max(a.y, b.y)
    return CGRect(x: x1, y: y1, width: x2 - x1, height: y2 - y1)
  }
    
    public var squareRect: CGRect {
        let width = min(abs(b.x - a.x), abs(b.y - a.y))
        let x = b.x < a.x ? a.x - width : a.x
        let y = b.y < a.y ? a.y - width : a.y
        return CGRect(x: x, y: y, width: width, height: width)
    }
    

  public var boundingRect: CGRect {
    return rect.insetBy(dx: -strokeWidth/2, dy: -strokeWidth/2)
  }
}

/**
 Special case of `Shape` where the shape is defined by exactly three points.
 */
public protocol ShapeWithThreePoints {
  var a: CGPoint { get set }
  var b: CGPoint { get set }
  var c: CGPoint { get set }
  
  var strokeWidth: CGFloat { get set }
}

extension ShapeWithThreePoints {
  public var rect: CGRect {
    let x1 = min(a.x, b.x, c.x)
    let y1 = min(a.y, b.y, c.y)
    let x2 = max(a.x, b.x, c.x)
    let y2 = max(a.y, b.y, c.y)
    return CGRect(x: x1, y: y1, width: x2 - x1, height: y2 - y1)
  }
  
  public var boundingRect: CGRect {
    return rect.insetBy(dx: -strokeWidth/2, dy: -strokeWidth/2)
  }
}
