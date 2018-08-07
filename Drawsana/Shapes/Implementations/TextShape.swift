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
  public var text = "" { didSet { updateCachedImage() } }
  public var fontName: String = "Helvetica Neue" { didSet { updateCachedImage() } }
  public var fontSize: CGFloat = 24 { didSet { updateCachedImage() } }
  public var fillColor: UIColor = .black { didSet { updateCachedImage() } }

  private var cachedImage: UIImage?

  public var boundingRect: CGRect {
    return CGRect(
      origin: CGPoint(x: -textView.frame.size.width / 2, y: -textView.frame.size.height / 2),
      size: textView.frame.size)
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

  public lazy var textView: UITextView = makeTextView()
  public var image: UIImage {
    if let cachedImage = cachedImage { return cachedImage }
    let size = CGSize(width: textView.bounds.size.width * transform.scale, height: textView.bounds.size.height * transform.scale)
    let image = DrawsanaUtilities.renderImage(size: size) { _ in
      (self.text as NSString).draw(in: CGRect(origin: .zero, size: size).insetBy(dx: 5, dy: 0), withAttributes: [
        .font: self.font,
        .foregroundColor: self.fillColor,
      ])
    }
    cachedImage = image
    return image!
  }

  public func render(in context: CGContext) {
    image.draw(at: computeFrame().origin)
  }

  public func updateCachedImage() {
    cachedImage = nil
  }

  func computeFrame() -> CGRect {
    let center = CGPoint(x: transform.translation.x, y: transform.translation.y)
    let textForMeasuring = text.isEmpty ? "__" : text
    let textSize = (textForMeasuring as NSString).boundingRect(
      with: CGSize(width: CGFloat.infinity, height: CGFloat.infinity),
      options: [.usesLineFragmentOrigin], attributes: [.font: font], context: nil)
    let scaledTextSize = CGSize(width: textSize.width * transform.scale, height: textSize.height * transform.scale)
    return CGRect(
      origin: CGPoint(x: center.x - scaledTextSize.width / 2, y: center.y - scaledTextSize.height / 2),
      size: scaledTextSize).insetBy(dx: -8, dy: -4) // TODO: allow config
  }

  private func makeTextView() -> UITextView {
    let textView = UITextView()
    textView.autoresizingMask = [.flexibleRightMargin, .flexibleBottomMargin]
    textView.frame = computeFrame()
    textView.font = font
    textView.textContainerInset = .zero
    textView.isScrollEnabled = false
    textView.clipsToBounds = true
    textView.autocorrectionType = .no
    textView.text = text
    return textView
  }
}
