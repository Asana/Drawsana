//
//  RectShape.swift
//  Drawsana
//
//  Created by Steve Landey on 8/2/18.
//  Copyright © 2018 Asana. All rights reserved.
//

import CoreGraphics
import UIKit

public class RectShape: ShapeWithBoundingRect, ShapeWithTwoPoints, ShapeWithStandardState, ShapeSelectable {
  public let type: String = "Rectangle"

  public var id: String = UUID().uuidString
  public var a: CGPoint = .zero
  public var b: CGPoint = .zero
  public var strokeColor: UIColor? = .black
  public var fillColor: UIColor? = .clear
  public var strokeWidth: CGFloat = 10
  public var capStyle: CGLineCap = .round
  public var joinStyle: CGLineJoin = .round
  public var dashPhase: CGFloat?
  public var dashLengths: [CGFloat]?
  public var transform: ShapeTransform = .identity

  public init() {

  }

  public func render(in context: CGContext) {
    transform.begin(context: context)
    context.setLineCap(capStyle)
    context.setLineJoin(joinStyle)
    context.setLineWidth(strokeWidth)
    if let strokeColor = strokeColor {
      context.setStrokeColor(strokeColor.cgColor)
      if let dashPhase = dashPhase, let dashLengths = dashLengths {
        context.setLineDash(phase: dashPhase, lengths: dashLengths)
      } else {
        context.setLineDash(phase: 0, lengths: [])
      }
      context.addRect(rect)
      context.strokePath()
    }

    if let fillColor = fillColor {
      context.setFillColor(fillColor.cgColor)
      context.addRect(rect)
      context.fillPath()
    }
    transform.end(context: context)
  }
}
