//
//  AMShape.swift
//  AMDrawingView
//
//  Created by Steve Landey on 7/23/18.
//  Copyright © 2018 Asana. All rights reserved.
//

import CoreGraphics
import UIKit

public protocol Shape: AnyObject {
  var id: String { get }
  var type: String { get }
  func render(in context: CGContext)
  func hitTest(point: CGPoint) -> Bool
}

public protocol ShapeWithBoundingRect: Shape {
  var boundingRect: CGRect { get }
}

extension ShapeWithBoundingRect {
  public func hitTest(point: CGPoint) -> Bool {
    return boundingRect.contains(point)
  }
}

public protocol ShapeWithTransform: Shape {
  var transform: ShapeTransform { get set }
}

public protocol ShapeSelectable: ShapeWithBoundingRect, ShapeWithTransform {
}
extension ShapeSelectable {
  public func hitTest(point: CGPoint) -> Bool {
    return boundingRect.applying(transform.affineTransform).contains(point)
  }
}

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

  public var boundingRect: CGRect {
    return rect.insetBy(dx: -strokeWidth/2, dy: -strokeWidth/2)
  }
}

public protocol AMShapeWithStandardState: AnyObject, ToolStateAppliable {
  var strokeColor: UIColor? { get set }
  var fillColor: UIColor? { get set }
  var strokeWidth: CGFloat { get set }
}

extension AMShapeWithStandardState {
  public func apply(state: UserSettings) {
    strokeColor = state.strokeColor
    fillColor = state.fillColor
    strokeWidth = state.strokeWidth
  }
}

public protocol AMShapeWithStrokeState: AnyObject, ToolStateAppliable {
  var strokeColor: UIColor { get set }
  var strokeWidth: CGFloat { get set }
}

extension AMShapeWithStrokeState {
  public func apply(state: UserSettings) {
    strokeColor = state.strokeColor ?? .black
    strokeWidth = state.strokeWidth
  }
}
