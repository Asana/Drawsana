//
//  Shape_Ellipse_Rect_Line.swift
//  Drawsana
//
//  Created by Steve Landey on 8/2/18.
//  Copyright © 2018 Asana. All rights reserved.
//

import UIKit

public class LineShape:
  ShapeWithTwoPoints,
  ShapeWithStrokeState,
  ShapeSelectable
{
  private enum CodingKeys: String, CodingKey {
    case id, a, b, strokeColor, strokeWidth, capStyle, joinStyle,
    dashPhase, dashLengths, transform, type, arrowStyle
  }

  public enum ArrowStyle: String, Codable {
    /// Plain old triangle
    case standard
  }

  public static let type: String = "Line"

  public var id: String = UUID().uuidString
  public var a: CGPoint = .zero
  public var b: CGPoint = .zero
  public var strokeColor: UIColor = .black
  public var strokeWidth: CGFloat = 10
  public var capStyle: CGLineCap = .round
  public var joinStyle: CGLineJoin = .round
  public var dashPhase: CGFloat?
  public var dashLengths: [CGFloat]?
  public var arrowStyle: ArrowStyle?
  public var transform: ShapeTransform = .identity

  public init() {
  }

  public required init(from decoder: Decoder) throws {
    let values = try decoder.container(keyedBy: CodingKeys.self)

    let type = try values.decode(String.self, forKey: .type)
    if type != LineShape.type {
      throw DrawsanaDecodingError.wrongShapeTypeError
    }

    id = try values.decode(String.self, forKey: .id)
    a = try values.decode(CGPoint.self, forKey: .a)
    b = try values.decode(CGPoint.self, forKey: .b)
    strokeColor = UIColor(hexString: try values.decode(String.self, forKey: .strokeColor))
    strokeWidth = try values.decode(CGFloat.self, forKey: .strokeWidth)
    arrowStyle = try values.decodeIfPresent(ArrowStyle.self, forKey: .arrowStyle)
    transform = try values.decodeIfPresent(ShapeTransform.self, forKey: .transform) ?? .identity

    capStyle = CGLineCap(rawValue: try values.decodeIfPresent(Int32.self, forKey: .capStyle) ?? CGLineCap.round.rawValue)!
    joinStyle = CGLineJoin(rawValue: try values.decodeIfPresent(Int32.self, forKey: .joinStyle) ?? CGLineJoin.round.rawValue)!
    dashPhase = try values.decodeIfPresent(CGFloat.self, forKey: .dashPhase)
    dashLengths = try values.decodeIfPresent([CGFloat].self, forKey: .dashLengths)
  }

  public func encode(to encoder: Encoder) throws {
    var container = encoder.container(keyedBy: CodingKeys.self)
    try container.encode(LineShape.type, forKey: .type)
    try container.encode(id, forKey: .id)
    try container.encode(a, forKey: .a)
    try container.encode(b, forKey: .b)
    try container.encode(strokeColor.hexString, forKey: .strokeColor)
    try container.encode(strokeWidth, forKey: .strokeWidth)
    try container.encodeIfPresent(arrowStyle, forKey: .arrowStyle)

    if !transform.isIdentity {
      try container.encode(transform, forKey: .transform)
    }

    if capStyle != .round {
      try container.encode(capStyle.rawValue, forKey: .capStyle)
    }
    if joinStyle != .round {
      try container.encode(joinStyle.rawValue, forKey: .joinStyle)
    }
    try container.encodeIfPresent(dashPhase, forKey: .dashPhase)
    try container.encodeIfPresent(dashLengths, forKey: .dashLengths)
  }

  public func render(in context: CGContext) {
    transform.begin(context: context)
    context.setLineCap(capStyle)
    context.setLineJoin(joinStyle)
    context.setLineWidth(strokeWidth)
    context.setStrokeColor(strokeColor.cgColor)
    if let dashPhase = dashPhase, let dashLengths = dashLengths {
      context.setLineDash(phase: dashPhase, lengths: dashLengths)
    } else {
      context.setLineDash(phase: 0, lengths: [])
    }
    context.move(to: a)
    context.addLine(to: b)
    context.strokePath()

    if case .some(.standard) = arrowStyle {
      renderArrow(in: context)
    }
    transform.end(context: context)
  }

  private func renderArrow(in context: CGContext) {
    let angle = atan2(b.y - a.y, b.x - a.x)
    let arcAmount: CGFloat = CGFloat.pi / 4
    let radius = strokeWidth * 4

    // Nudge arrow out past end of line a little so it doesn't let the line below show through when it's thick
    let arrowOffset = CGPoint(angle: angle, radius: strokeWidth * 2)

    let startPoint = b + arrowOffset
    let point1 = b + CGPoint(angle: angle + arcAmount / 2 + CGFloat.pi, radius: radius) + arrowOffset
    let point2 = b + CGPoint(angle: angle - arcAmount / 2 + CGFloat.pi, radius: radius) + arrowOffset

    context.setLineWidth(0)
    context.setFillColor(strokeColor.cgColor)
    context.move(to: startPoint)
    context.addLine(to: point1)
    context.addLine(to: point2)
    context.fillPath()
  }
}
