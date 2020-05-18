//
//  PenShape.swift
//  Drawsana
//
//  Created by Steve Landey on 8/2/18.
//  Copyright © 2018 Asana. All rights reserved.
//

import UIKit

public struct PenLineSegment: Codable, Equatable {
  public var a: CGPoint
  public var b: CGPoint
  public var width: CGFloat

  public init(a: CGPoint, b: CGPoint, width: CGFloat) {
    self.a = a
    self.b = b
    self.width = width
  }

  public var midPoint: CGPoint {
    return CGPoint(x: (a.x + b.x) / 2, y: (a.y + b.y) / 2)
  }
}

public class PenShape: Shape, ShapeWithStrokeState, ShapeSelectable {
  private enum CodingKeys: String, CodingKey {
    case id, isFinished, strokeColor, start, strokeWidth, segments, isEraser, type, transform
  }

  public static let type: String = "Pen"

  public var id: String = UUID().uuidString
  public var isFinished = true
  public var start: CGPoint = .zero
  public var strokeColor: UIColor = .black
  public var strokeWidth: CGFloat = 10
  public var segments: [PenLineSegment] = []
  public var isEraser: Bool = false
  public var transform: ShapeTransform = .identity

  public var boundingRect: CGRect {
    var minX = start.x, maxX = start.x
    var minY = start.y, maxY = start.y
    
    for segment in segments {
      let x = segment.b.x
      let y = segment.b.y
      if x < minX { minX = x }
      if x > maxX { maxX = x }
      if y < minY { minY = y }
      if y > maxY { maxY = y }
    }
    let minimalRect = CGRect(x: minX, y: minY, width: maxX - minX, height: maxY - minY)
    return minimalRect.insetBy(dx: -strokeWidth/2, dy: -strokeWidth/2)
  }

  public init() {
  }

  public required init(from decoder: Decoder) throws {
    let values = try decoder.container(keyedBy: CodingKeys.self)

    let type = try values.decode(String.self, forKey: .type)
    if type != PenShape.type {
      throw DrawsanaDecodingError.wrongShapeTypeError
    }

    id = try values.decode(String.self, forKey: .id)
    isFinished = try values.decode(Bool.self, forKey: .isFinished)
    start = try values.decode(CGPoint.self, forKey: .start)
    strokeColor = UIColor(hexString: try values.decode(String.self, forKey: .strokeColor))
    strokeWidth = try values.decode(CGFloat.self, forKey: .strokeWidth)
    segments = try values.decode([PenLineSegment].self, forKey: .segments)
    isEraser = try values.decode(Bool.self, forKey: .isEraser)
    transform = try values.decodeIfPresent(ShapeTransform.self, forKey: .transform) ?? .identity
  }

  public func encode(to encoder: Encoder) throws {
    var container = encoder.container(keyedBy: CodingKeys.self)
    try container.encode(PenShape.type, forKey: .type)
    try container.encode(id, forKey: .id)
    try container.encode(isFinished, forKey: .isFinished)
    try container.encode(start, forKey: .start)
    try container.encode(strokeColor.hexString, forKey: .strokeColor)
    try container.encode(strokeWidth, forKey: .strokeWidth)
    try container.encode(segments, forKey: .segments)
    try container.encode(isEraser, forKey: .isEraser)
    if !transform.isIdentity {
      try container.encode(transform, forKey: .transform)
    }
  }

  public func add(segment: PenLineSegment) {
    segments.append(segment)
  }

  private func render(in context: CGContext, onlyLast: Bool = false) {
    transform.begin(context: context)
    context.saveGState()
    if isEraser {
      context.setBlendMode(.clear)
    }

    guard !segments.isEmpty else {
      if isFinished {
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
    var lastWidth = segments[0].width
    var hasStroked = false // make sure we finally stroke the path
    for (i, segment) in (onlyLast ? [segments.last!] : segments).enumerated() {
      hasStroked = false
      let needsStroke = segment.width != lastWidth
      context.setLineWidth(segment.width)
      if let previousMid = lastSegment?.midPoint {
        let currentMid = segment.midPoint
        context.move(to: previousMid)
        context.addQuadCurve(to: currentMid, control: segment.a)
        // Usually we only draw up to the mid point of the segment, but if the
        // shape is done and this is the last segment, go ahead and draw a line
        // to the end
        if i == segments.count - 1 && isFinished {
          context.addLine(to: segment.b)
        }
      } else if segments.count == 1 {
        context.move(to: segment.a)
        context.addLine(to: segment.b)
      } else {
        context.move(to: segment.a)
        context.addLine(to: segment.midPoint)
      }

      if needsStroke {
        context.strokePath()
        hasStroked = true
      }

      lastWidth = segment.width
      lastSegment = segment
    }

    if !hasStroked {
      context.strokePath()
    }
    context.restoreGState()
    transform.end(context: context)
  }

  public func render(in context: CGContext) {
    render(in: context, onlyLast: false)
  }

  public func renderLatestSegment(in context: CGContext) {
    render(in: context, onlyLast: true)
  }
}
