//
//  TextShape.swift
//  Drawsana
//
//  Created by Steve Landey on 8/3/18.
//  Copyright © 2018 Asana. All rights reserved.
//

import UIKit

public class TextShape: Shape, ShapeSelectable {
  private enum CodingKeys: String, CodingKey {
    case id, transform, text, fontName, fontSize, fillColor, type,
      explicitWidth, boundingRect
  }

  public static let type = "Text"

  public var id: String = UUID().uuidString
  /// This shape is positioned entirely with `TextShape.transform.translate`,
  /// rather than storing an explicit position.
  public var transform: ShapeTransform = .identity
  public var text = ""
  public var fontName: String = "Helvetica Neue"
  public var fontSize: CGFloat = 24
  public var fillColor: UIColor = .black
  /// If user drags the text box to an exact width, we need to respect it instead
  /// of automatically sizing the text box to fit the text.
  public var explicitWidth: CGFloat?

  /// Set to true if this text is being shown in some other way, i.e. in a
  /// `UITextView` that the user is editing.
  public var isBeingEdited: Bool = false

  public var boundingRect: CGRect = .zero

  var font: UIFont {
    return UIFont(name: fontName, size: fontSize)!
  }

  public init() {
  }

  public required init(from decoder: Decoder) throws {
    let values = try decoder.container(keyedBy: CodingKeys.self)

    let type = try values.decode(String.self, forKey: .type)
    if type != TextShape.type {
      throw DrawsanaDecodingError.wrongShapeTypeError
    }

    id = try values.decode(String.self, forKey: .id)
    text = try values.decode(String.self, forKey: .text)
    fontName = try values.decode(String.self, forKey: .fontName)
    fontSize = try values.decode(CGFloat.self, forKey: .fontSize)
    fillColor = UIColor(hexString: try values.decode(String.self, forKey: .fillColor))
    explicitWidth = try values.decodeIfPresent(CGFloat.self, forKey: .explicitWidth)
    boundingRect = try values.decodeIfPresent(CGRect.self, forKey: .boundingRect) ?? .zero
    transform = try values.decode(ShapeTransform.self, forKey: .transform)

    if boundingRect == .zero {
      print("Text bounding rect not present. This shape will not render correctly because of a bug in Drawsana <0.10.0.")
    }
  }

  public func encode(to encoder: Encoder) throws {
    var container = encoder.container(keyedBy: CodingKeys.self)
    try container.encode(TextShape.type, forKey: .type)
    try container.encode(id, forKey: .id)
    try container.encode(text, forKey: .text)
    try container.encode(fontName, forKey: .fontName)
    try container.encode(fillColor.hexString, forKey: .fillColor)
    try container.encode(fontSize, forKey: .fontSize)
    try container.encodeIfPresent(explicitWidth, forKey: .explicitWidth)
    try container.encode(transform, forKey: .transform)
    try container.encode(boundingRect, forKey: .boundingRect)
  }

  public func render(in context: CGContext) {
    if isBeingEdited { return }
    transform.begin(context: context)
    (self.text as NSString).draw(
      in: CGRect(origin: boundingRect.origin, size: self.boundingRect.size),
      withAttributes: [
        .font: self.font,
        .foregroundColor: self.fillColor,
      ])
    transform.end(context: context)
  }

  public func apply(userSettings: UserSettings) {
    fillColor = userSettings.strokeColor ?? .black
    fontName = userSettings.fontName
    fontSize = userSettings.fontSize
  }
}
