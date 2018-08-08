//
//  TextShapeEditingView.swift
//  Drawsana
//
//  Created by Steve Landey on 8/8/18.
//  Copyright © 2018 Asana. All rights reserved.
//

import UIKit

public class TextShapeEditingView: UIView {
  /// Upper left 'delete' button for text. You may add any subviews you want,
  /// set border & background color, etc.
  public let deleteControlView = UIView()
  /// Lower right 'rotate' button for text. You may add any subviews you want,
  /// set border & background color, etc.
  public let resizeAndRotateControlView = UIView()
  /// Right side handle to change width of text. You may add any subviews you
  /// want, set border & background color, etc.
  public let changeWidthControlView = UIView()

  /// The `UITextView` that the user interacts with during editing
  public let textView: UITextView

  enum PointArea {
    case delete
    case resizeAndRotate
    case changeWidth
    case none
  }

  init(textView: UITextView) {
    self.textView = textView
    super.init(frame: .zero)

    clipsToBounds = false
    backgroundColor = .clear
    layer.isOpaque = false

    textView.translatesAutoresizingMaskIntoConstraints = false

    deleteControlView.translatesAutoresizingMaskIntoConstraints = false
    deleteControlView.backgroundColor = .red

    resizeAndRotateControlView.translatesAutoresizingMaskIntoConstraints = false
    resizeAndRotateControlView.backgroundColor = .white

    changeWidthControlView.translatesAutoresizingMaskIntoConstraints = false
    changeWidthControlView.backgroundColor = .yellow

    addSubview(textView)
    addSubview(deleteControlView)
    addSubview(resizeAndRotateControlView)
    addSubview(changeWidthControlView)

    NSLayoutConstraint.activate([
      textView.leftAnchor.constraint(equalTo: leftAnchor),
      textView.rightAnchor.constraint(equalTo: rightAnchor),
      textView.topAnchor.constraint(equalTo: topAnchor),
      textView.bottomAnchor.constraint(equalTo: bottomAnchor),

      deleteControlView.widthAnchor.constraint(equalToConstant: 36),
      deleteControlView.heightAnchor.constraint(equalToConstant: 36),
      deleteControlView.rightAnchor.constraint(equalTo: textView.leftAnchor),
      deleteControlView.bottomAnchor.constraint(equalTo: textView.topAnchor, constant: -3),

      resizeAndRotateControlView.widthAnchor.constraint(equalToConstant: 36),
      resizeAndRotateControlView.heightAnchor.constraint(equalToConstant: 36),
      resizeAndRotateControlView.leftAnchor.constraint(equalTo: textView.rightAnchor, constant: 5),
      resizeAndRotateControlView.topAnchor.constraint(equalTo: textView.bottomAnchor, constant: 4),

      changeWidthControlView.widthAnchor.constraint(equalToConstant: 36),
      changeWidthControlView.heightAnchor.constraint(equalToConstant: 36),
      changeWidthControlView.leftAnchor.constraint(equalTo: textView.rightAnchor, constant: 5),
      changeWidthControlView.bottomAnchor.constraint(equalTo: textView.topAnchor, constant: -4),
      ])
  }

  required public init?(coder aDecoder: NSCoder) {
    fatalError()
  }

  override public func sizeThatFits(_ size: CGSize) -> CGSize {
    return textView.sizeThatFits(size)
  }

  @discardableResult
  override public func becomeFirstResponder() -> Bool {
    return textView.becomeFirstResponder()
  }

  @discardableResult
  override public func resignFirstResponder() -> Bool {
    return textView.resignFirstResponder()
  }

  func getPointArea(point: CGPoint) -> PointArea {
    guard let superview = superview else { return .none }
    if deleteControlView.convert(deleteControlView.bounds, to: superview).contains(point) {
      return .delete
    } else if resizeAndRotateControlView.convert(resizeAndRotateControlView.bounds, to: superview).contains(point) {
      return .resizeAndRotate
    } else if changeWidthControlView.convert(changeWidthControlView.bounds, to: superview).contains(point) {
      return .changeWidth
    } else {
      return .none
    }
  }
}
