//
//  EllipseShape.swift
//  Drawsana
//
//  Created by Steve Landey on 8/2/18.
//  Copyright © 2018 Asana. All rights reserved.
//

import UIKit

public class EllipseShape:
  ShapeWithTwoPoints,
  ShapeWithStandardState,
  ShapeSelectable
{
  private enum CodingKeys: String, CodingKey {
    case id, a, b, strokeColor, fillColor, strokeWidth, capStyle, joinStyle,
    dashPhase, dashLengths, transform, type
  }

  public static let type: String = "Ellipse"

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

  public required init(from decoder: Decoder) throws {
    let values = try decoder.container(keyedBy: CodingKeys.self)
    
    let type = try values.decode(String.self, forKey: .type)
    if type != EllipseShape.type {
      throw DrawsanaDecodingError.wrongShapeTypeError
    }

    id = try values.decode(String.self, forKey: .id)
    a = try values.decode(CGPoint.self, forKey: .a)
    b = try values.decode(CGPoint.self, forKey: .b)
    
    strokeColor = try values.decodeColorIfPresent(forKey: .strokeColor)
    fillColor = try values.decodeColorIfPresent(forKey: .fillColor)

    strokeWidth = try values.decode(CGFloat.self, forKey: .strokeWidth)
    transform = try values.decodeIfPresent(ShapeTransform.self, forKey: .transform) ?? .identity

    capStyle = CGLineCap(rawValue: try values.decodeIfPresent(Int32.self, forKey: .capStyle) ?? CGLineCap.round.rawValue)!
    joinStyle = CGLineJoin(rawValue: try values.decodeIfPresent(Int32.self, forKey: .joinStyle) ?? CGLineJoin.round.rawValue)!
    dashPhase = try values.decodeIfPresent(CGFloat.self, forKey: .dashPhase)
    dashLengths = try values.decodeIfPresent([CGFloat].self, forKey: .dashLengths)
  }

  public func encode(to encoder: Encoder) throws {
    var container = encoder.container(keyedBy: CodingKeys.self)
    try container.encode(EllipseShape.type, forKey: .type)
    try container.encode(id, forKey: .id)
    try container.encode(a, forKey: .a)
    try container.encode(b, forKey: .b)
    try container.encode(strokeColor?.hexString, forKey: .strokeColor)
    try container.encode(fillColor?.hexString, forKey: .fillColor)
    try container.encode(strokeWidth, forKey: .strokeWidth)

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

    if let fillColor = fillColor {
      context.setFillColor(fillColor.cgColor)
      context.addEllipse(in: rect)
      context.fillPath()
    }

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

      context.addEllipse(in: rect)
      context.strokePath()
    }
    
    transform.end(context: context)
  }
}
