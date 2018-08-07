//
//  TextShape.swift
//  Drawsana
//
//  Created by Steve Landey on 8/3/18.
//  Copyright © 2018 Asana. All rights reserved.
//

import CoreGraphics
import UIKit

// TODO: move `textView` out of here into `TextTool`

public class TextShape: Shape, ShapeSelectable {
  private enum CodingKeys: String, CodingKey {
    case id, transform, text, fontName, fontSize, fillColor, type
  }

  public static let type = "Text"

  public var id: String = UUID().uuidString
  public var transform: ShapeTransform = .identity
  public var isBeingEdited: Bool = false
  public var text = "" { didSet { updateCachedImage() } }
  public var fontName: String = "Helvetica Neue" { didSet { updateCachedImage() } }
  public var fontSize: CGFloat = 24 { didSet { updateCachedImage() } }
  public var fillColor: UIColor = .black { didSet { updateCachedImage() } }

  private var cachedImage: UIImage?

  public var boundingRect: CGRect = .zero

  var insets: CGPoint {
    return CGPoint(x: -8, y: -4)
  }

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
    transform = try values.decode(ShapeTransform.self, forKey: .transform)
  }

  public func encode(to encoder: Encoder) throws {
    var container = encoder.container(keyedBy: CodingKeys.self)
    try container.encode(TextShape.type, forKey: .type)
    try container.encode(id, forKey: .id)
    try container.encode(text, forKey: .text)
    try container.encode(fontName, forKey: .fontName)
    try container.encode(fillColor.hexString, forKey: .fillColor)
    try container.encode(fontSize, forKey: .fontSize)
    try container.encode(transform, forKey: .transform)
  }

  public var image: UIImage {
    if let cachedImage = cachedImage { return cachedImage }
    let size = CGSize(width: boundingRect.size.width * transform.scale, height: boundingRect.size.height * transform.scale)
    let image = DrawsanaUtilities.renderImage(size: size) { _ in
      (self.text as NSString).draw(in: CGRect(origin: CGPoint(x: 3, y: 0), size: self.boundingRect.size), withAttributes: [
        .font: self.font,
        .foregroundColor: self.fillColor,
        .strokeColor: self.fillColor,
      ])
    }
    cachedImage = image
    return image!
  }

  public func render(in context: CGContext) {
    if isBeingEdited { return }
    transform.begin(context: context)
    image.draw(at: boundingRect.origin)
    transform.end(context: context)
  }

  public func updateCachedImage() {
    cachedImage = nil
  }
}
