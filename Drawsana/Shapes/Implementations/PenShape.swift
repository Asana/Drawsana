//
//  PenShape.swift
//  Drawsana
//
//  Created by Steve Landey on 8/2/18.
//  Copyright © 2018 Asana. All rights reserved.
//

import CoreGraphics
import UIKit

public struct PenLineSegment {
  var a: CGPoint
  var b: CGPoint
  var width: CGFloat

  var midPoint: CGPoint {
    return CGPoint(x: (a.x + b.x) / 2, y: (a.y + b.y) / 2)
  }
}

public class PenShape: Shape, ShapeWithStrokeState {
  public let type: String = "Pen"

  public var id: String = UUID().uuidString
  public var isFinished = true
  public var strokeColor: UIColor = .black
  public var start: CGPoint = .zero
  public var strokeWidth: CGFloat = 10
  public var segments: [PenLineSegment] = []
  public var isEraser: Bool = false

  public var isSelectable: Bool { return false }
  public func hitTest(point: CGPoint) -> Bool {
    return false
  }

  public func add(segment: PenLineSegment) {
    segments.append(segment)
  }

  private func render(in context: CGContext, onlyLast: Bool = false) {
    context.saveGState()
    if isEraser {
      context.setBlendMode(.clear)
    }

    guard !segments.isEmpty else {
      if !isFinished {
        // Draw a dot
        context.setFillColor(strokeColor.cgColor)
        context.addArc(center: start, radius: strokeWidth / 2, startAngle: 0, endAngle: 2 * CGFloat.pi, clockwise: true)
        context.fillPath()
      } else {
        // draw nothing; user will keep drawing
      }
      context.restoreGState()
      return
    }

    context.setLineCap(.round)
    context.setLineJoin(.round)
    context.setStrokeColor(strokeColor.cgColor)

    var lastSegment: PenLineSegment?
    if onlyLast, segments.count > 1 {
      lastSegment = segments[segments.count - 2]
    }
    for segment in (onlyLast ? [segments.last!] : segments) {
      context.setLineWidth(segment.width)
      if let previousMid = lastSegment?.midPoint {
        let currentMid = segment.midPoint
        context.move(to: previousMid)
        context.addQuadCurve(to: currentMid, control: segment.a)
        context.strokePath()
      } else {
        context.move(to: segment.a)
        context.addLine(to: segment.b)
        context.strokePath()
      }
      lastSegment = segment
    }
    context.restoreGState()
  }

  public func render(in context: CGContext) {
    render(in: context, onlyLast: false)
  }

  public func renderLatestSegment(in context: CGContext) {
    render(in: context, onlyLast: true)
  }
}
