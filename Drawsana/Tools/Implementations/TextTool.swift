//
//  TextTool.swift
//  Drawsana
//
//  Created by Steve Landey on 8/2/18.
//  Copyright © 2018 Asana. All rights reserved.
//

import CoreGraphics
import UIKit

private class TextShapeEditingView: UIView {
  let deleteControlView = UIView()
  let resizeAndRotateControlView = UIView()
  let textView: UITextView

  enum PointArea {
    case delete
    case resizeAndRotate
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

    addSubview(textView)
    addSubview(deleteControlView)
    addSubview(resizeAndRotateControlView)

    NSLayoutConstraint.activate([
      textView.leftAnchor.constraint(equalTo: leftAnchor),
      textView.rightAnchor.constraint(equalTo: rightAnchor),
      textView.topAnchor.constraint(equalTo: topAnchor),
      textView.bottomAnchor.constraint(equalTo: bottomAnchor),

      deleteControlView.widthAnchor.constraint(equalToConstant: 36),
      deleteControlView.heightAnchor.constraint(equalToConstant: 36),
      deleteControlView.rightAnchor.constraint(equalTo: textView.leftAnchor),
      deleteControlView.bottomAnchor.constraint(equalTo: textView.topAnchor),

      resizeAndRotateControlView.widthAnchor.constraint(equalToConstant: 36),
      resizeAndRotateControlView.heightAnchor.constraint(equalToConstant: 36),
      resizeAndRotateControlView.leftAnchor.constraint(equalTo: textView.rightAnchor),
      resizeAndRotateControlView.topAnchor.constraint(equalTo: textView.bottomAnchor),
    ])
  }

  required init?(coder aDecoder: NSCoder) {
    fatalError()
  }

  override func sizeThatFits(_ size: CGSize) -> CGSize {
    return textView.sizeThatFits(size)
  }

  @discardableResult
  override func becomeFirstResponder() -> Bool {
    return textView.becomeFirstResponder()
  }

  @discardableResult
  override func resignFirstResponder() -> Bool {
    return textView.resignFirstResponder()
  }

  func getPointArea(point: CGPoint) -> PointArea {
    if deleteControlView.convert(deleteControlView.bounds, to: superview!).contains(point) {
      return .delete
    } else if resizeAndRotateControlView.convert(resizeAndRotateControlView.bounds, to: superview!).contains(point) {
      return .resizeAndRotate
    } else {
      return .none
    }
  }
}

public class TextTool: NSObject, DrawingTool {
  private enum DragType {
    case move
    case resizeAndRotate
    case none
  }

  public let isProgressive = false
  public let name: String = "Text"
  public weak var delegate: TextToolDelegate?

  public var shapeInProgress: TextShape?

  var originalTransform: ShapeTransform?
  var startPoint: CGPoint?
  var originalText = ""
  private var dragType: DragType = .none  // updated by handleDragStart

  private var maxWidth: CGFloat = 320  // updated from drawing
  private var maxWidthDueToScreenOverrun: CGFloat? = nil
  private weak var shapeUpdater: DrawsanaViewShapeUpdating?

  fileprivate lazy var textView: TextShapeEditingView = makeTextView()

  public init(delegate: TextToolDelegate? = nil) {
    self.delegate = delegate
    super.init()
    updateTextView()
  }

  // MARK: Begin/end editing actions

  private func beginEditing(shape: TextShape, context: ToolOperationContext) {
    shape.isBeingEdited = true // stop rendering this shape while textView is open
    maxWidth = max(maxWidth, context.drawing.size.width)
    context.toolSettings.interactiveView = textView
    shapeInProgress = shape
    updateShapeFrame()
    // set toolSettings.selectedShape after computing frame so initial selection
    // rect is accurate
    context.toolSettings.selectedShape = shape
    textView.becomeFirstResponder()
    originalText = shape.text
  }

  /// If shape text has changed, notify operation stack so that undo works
  /// properly
  private func applyTextEditingOperation(context: ToolOperationContext) {
    if let shape = shapeInProgress {
      if originalText != shape.text {
        context.operationStack.apply(operation: EditTextOperation(shape: shape, originalText: originalText, text: shape.text))
        originalText = shape.text
      }

      shape.isBeingEdited = false
      context.toolSettings.isPersistentBufferDirty = true
    }
  }

  private func applyRemoveShapeOperation(context: ToolOperationContext) {
    guard let shape = shapeInProgress else { return }
    textView.resignFirstResponder()
    shape.isBeingEdited = false
    context.operationStack.apply(operation: RemoveShapeOperation(shape: shape))
    shapeInProgress = nil
    context.toolSettings.selectedShape = nil
    context.toolSettings.isPersistentBufferDirty = true
    context.toolSettings.interactiveView = nil
  }

  // MARK: Tool lifecycle

  public func activate(shapeUpdater: DrawsanaViewShapeUpdating, context: ToolOperationContext, shape: Shape?) {
    self.shapeUpdater = shapeUpdater
    if let shape = shape as? TextShape {
      beginEditing(shape: shape, context: context)
    }
  }

  public func deactivate(context: ToolOperationContext) {
    context.toolSettings.interactiveView?.resignFirstResponder()
    context.toolSettings.interactiveView = nil
    applyTextEditingOperation(context: context)
  }

  public func handleTap(context: ToolOperationContext, point: CGPoint) {
    maxWidthDueToScreenOverrun = nil

    if let shapeInProgress = self.shapeInProgress {
      handleTapWhenShapeIsActive(context: context, point: point, shape: shapeInProgress)
    } else {
      handleTapWhenNoShapeIsActive(context: context, point: point)
    }
  }

  private func handleTapWhenShapeIsActive(context: ToolOperationContext, point: CGPoint, shape: TextShape) {
    if case .delete = textView.getPointArea(point: point) {
      applyRemoveShapeOperation(context: context)
      delegate?.textToolDidTapAway(tappedPoint: point)
    } else if shape.hitTest(point: point) {
      // TODO: forward tap to text view
    } else {
      applyTextEditingOperation(context: context)
      self.shapeInProgress = nil
      context.toolSettings.selectedShape = nil
      context.toolSettings.interactiveView?.resignFirstResponder()
      context.toolSettings.interactiveView = nil
      shape.updateCachedImage()
      delegate?.textToolDidTapAway(tappedPoint: point)
    }
    return
  }

  private func handleTapWhenNoShapeIsActive(context: ToolOperationContext, point: CGPoint) {
    if let tappedShape = context.drawing.getShape(of: TextShape.self, at: point) {
      beginEditing(shape: tappedShape, context: context)
      context.toolSettings.isPersistentBufferDirty = true
    } else {
      let newShape = TextShape()
      newShape.fillColor = context.userSettings.strokeColor ?? .black
      self.shapeInProgress = newShape
      newShape.transform.translation = delegate?.textToolPointForNewText(tappedPoint: point) ?? point
      beginEditing(shape: newShape, context: context)
      updateShapeFrame()
      context.operationStack.apply(operation: AddShapeOperation(shape: newShape))
    }
  }

  public func handleDragStart(context: ToolOperationContext, point: CGPoint) {
    guard let shapeInProgress = shapeInProgress else { return }
    if case .resizeAndRotate = textView.getPointArea(point: point) {
      dragType = .resizeAndRotate
      originalTransform = shapeInProgress.transform
      startPoint = point
      maxWidthDueToScreenOverrun = nil
    } else if shapeInProgress.hitTest(point: point) {
      dragType = .move
      originalTransform = shapeInProgress.transform
      startPoint = point
      maxWidthDueToScreenOverrun = nil
    } else {
      dragType = .none
    }
  }

  private func getResizeAndRotateTransform(originalTransform: ShapeTransform, startPoint: CGPoint, point: CGPoint, selectedShape: ShapeSelectable) -> ShapeTransform {
    let originalDelta = CGPoint(x: startPoint.x - selectedShape.transform.translation.x, y: startPoint.y - selectedShape.transform.translation.y)
    let newDelta = CGPoint(x: point.x - selectedShape.transform.translation.x, y: point.y - selectedShape.transform.translation.y)
    let originalDistance = originalDelta.length
    let newDistance = newDelta.length
    let originalAngle = atan2(originalDelta.y, originalDelta.x)
    let newAngle = atan2(newDelta.y, newDelta.x)
    let scaleChange = newDistance / originalDistance
    let angleChange = newAngle - originalAngle
    return originalTransform.scaled(by: scaleChange).rotated(by: angleChange)
  }

  public func handleDragContinue(context: ToolOperationContext, point: CGPoint, velocity: CGPoint) {
    guard
      let originalTransform = originalTransform,
      let selectedShape = context.toolSettings.selectedShape,
      let startPoint = startPoint else
    {
      return
    }
    switch dragType {
    case .move:
      let delta = CGPoint(x: point.x - startPoint.x, y: point.y - startPoint.y)
      selectedShape.transform = originalTransform.translated(by: delta)
    case .resizeAndRotate:
      selectedShape.transform = getResizeAndRotateTransform(originalTransform: originalTransform, startPoint: startPoint, point: point, selectedShape: selectedShape)
    default:
      break
    }
    updateTextView()
  }

  public func handleDragEnd(context: ToolOperationContext, point: CGPoint) {
    guard
      let originalTransform = originalTransform,
      let selectedShape = context.toolSettings.selectedShape,
      let startPoint = startPoint else
    {
      return
    }
    switch dragType {
    case .move:
      let delta = CGPoint(x: point.x - startPoint.x, y: point.y - startPoint.y)
      context.operationStack.apply(operation: ChangeTransformOperation(
        shape: selectedShape,
        transform: originalTransform.translated(by: delta),
        originalTransform: originalTransform))
    case .resizeAndRotate:
      context.operationStack.apply(operation: ChangeTransformOperation(
        shape: selectedShape,
        transform: getResizeAndRotateTransform(originalTransform: originalTransform, startPoint: startPoint, point: point, selectedShape: selectedShape),
        originalTransform: originalTransform))
    case .none:
      break
    }
    context.toolSettings.isPersistentBufferDirty = true
    updateTextView()
  }

  public func handleDragCancel(context: ToolOperationContext, point: CGPoint) {
    context.toolSettings.selectedShape?.transform = originalTransform ?? .identity
    context.toolSettings.isPersistentBufferDirty = true
    updateShapeFrame()
  }

  // MARK: Helpers

  private func updateShapeFrame() {
    guard let shape = shapeInProgress else { return }
    shape.boundingRect = computeBounds()
    shape.boundingRect.origin.x += 2
    updateTextView()
  }

  private func updateTextView() {
    guard let shape = shapeInProgress else { return }
    textView.textView.text = shape.text
    textView.textView.font = shape.font
    textView.textView.textColor = shape.fillColor
    textView.bounds = shape.boundingRect
    textView.bounds.size.width += 3
    textView.transform = CGAffineTransform(
      translationX: -shape.boundingRect.size.width / 2,
      y: -shape.boundingRect.size.height / 2
    ).concatenating(shape.transform.affineTransform)

    textView.setNeedsLayout()
    textView.layoutIfNeeded()
  }

  func computeBounds() -> CGRect {
    updateTextView()
    var textSize = textView.sizeThatFits(CGSize(width: min(maxWidth, maxWidthDueToScreenOverrun ?? .infinity), height: .infinity))
    textSize.width = max(textSize.width, 44)
    return CGRect(origin: CGPoint(x: -textSize.width / 2, y: -textSize.height / 2), size: textSize)
  }

  private func makeTextView() -> TextShapeEditingView {
    let textView = UITextView()
    textView.autoresizingMask = [.flexibleRightMargin, .flexibleBottomMargin]
    textView.textContainerInset = .zero
    textView.contentInset = .zero
    textView.isScrollEnabled = false
    textView.clipsToBounds = true
    textView.autocorrectionType = .no
    textView.backgroundColor = .clear
    textView.delegate = self
    return TextShapeEditingView(textView: textView)
  }
}

extension TextTool: UITextViewDelegate {
  public func textViewDidChange(_ textView: UITextView) {
    guard let shape = shapeInProgress else { return }
    maxWidthDueToScreenOverrun = maxWidth - (shape.boundingRect.origin.x + shape.transform.translation.x)
    shape.text = textView.text ?? ""
    updateShapeFrame()
    shapeUpdater?.shapeDidUpdate(shape: shape)
  }

  public func textViewDidBeginEditing(_ textView: UITextView) {
    shapeInProgress?.isBeingEdited = true
  }

  public func textViewShouldEndEditing(_ textView: UITextView) -> Bool {
    shapeInProgress?.isBeingEdited = false
    return true
  }
}

public protocol TextToolDelegate: AnyObject {
  /// Given the point where the user tapped, return the point where a text
  /// shape should be created. You might want to set it to a specific point, or
  /// make sure it's above the keyboard.
  func textToolPointForNewText(tappedPoint: CGPoint) -> CGPoint

  /// User tapped away from the active text shape. If you give users access to
  /// the selection tool, you might want to set it as the active tool at this
  /// point.
  func textToolDidTapAway(tappedPoint: CGPoint)
}
