//
//  TextShape.swift
//  Drawsana
//
//  Created by Steve Landey on 8/3/18.
//  Copyright © 2018 Asana. All rights reserved.
//

import CoreGraphics
import UIKit

public class TextShape: Shape, ShapeSelectable {
  public var id: String = UUID().uuidString
  public let type = "Text"

  public var boundingRect: CGRect {
    return CGRect(
      origin: CGPoint(x: -textView.frame.size.width / 2, y: -textView.frame.size.height / 2),
      size: textView.frame.size)
  }

  public var transform: ShapeTransform = .identity
  public var text = "" { didSet { cachedImage = nil } }
  public var fontName: String = "Helvetica Neue" { didSet { cachedImage = nil } }
  public var fontSize: CGFloat = 24 { didSet { cachedImage = nil } }

  var font: UIFont {
    return UIFont(name: fontName, size: fontSize)!
  }

  public lazy var textView: UITextView = makeTextView()
  private var cachedImage: UIImage?
  public var image: UIImage {
    if let cachedImage = cachedImage { return cachedImage }
    let size = CGSize(width: textView.bounds.size.width * transform.scale, height: textView.bounds.size.height * transform.scale)
    let image = DrawsanaUtilities.renderImage(size: size) { _ in
      (self.text as NSString).draw(in: CGRect(origin: .zero, size: size).insetBy(dx: 5, dy: 0), withAttributes: [
        .font: self.font,
//        .foregroundColor:
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
