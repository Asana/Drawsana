//
//  TextTool.swift
//  Drawsana
//
//  Created by Steve Landey on 8/2/18.
//  Copyright © 2018 Asana. All rights reserved.
//

import CoreGraphics
import UIKit

public class TextTool: NSObject, DrawingTool, UserSettingsApplying {
  /// When the user drags over the drawing view, this tool uses one of four
  /// behaviors, determined when the gesture starts.
  private enum DragType {
    /// Change the shape's transform.translation
    case move
    /// Change the shape's transform.{scale|rotation}
    case resizeAndRotate
    /// Change the text's explicit width
    case changeWidth
    /// Do nothing during this drag
    case none
  }

  /// MARK: Protocol requirements

  public let isProgressive = false
  public let name: String = "Text"

  // MARK: Public properties

  public weak var delegate: TextToolDelegate?

  // MARK: Internal state

  private var shapeInProgress: TextShape?
  private var originalTransform: ShapeTransform?
  private var startPoint: CGPoint?
  private var originalText = ""
  private var originalWidth: CGFloat?
  private var originalBoundingRect: CGRect = .zero
  private var dragType: DragType = .none  // updated by handleDragStart
  private var maxWidth: CGFloat = 320  // updated from drawing
  private weak var shapeUpdater: DrawsanaViewShapeUpdating?
  private lazy var editingView: TextShapeEditingView = makeTextView()

  public init(delegate: TextToolDelegate? = nil) {
    self.delegate = delegate
    super.init()
    updateTextView()
  }

  // MARK: Begin/end editing actions

  private func beginEditing(shape: TextShape, context: ToolOperationContext) {
    shape.isBeingEdited = true // stop rendering this shape while textView is open
    maxWidth = max(maxWidth, context.drawing.size.width)
    context.toolSettings.interactiveView = editingView
    shapeUpdater?.shapeDidUpdate(shape: shape)
    shapeInProgress = shape
    updateShapeFrame()
    // set toolSettings.selectedShape after computing frame so initial selection
    // rect is accurate
    context.toolSettings.selectedShape = shape
    editingView.becomeFirstResponder()
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
    editingView.resignFirstResponder()
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
    if let shapeInProgress = self.shapeInProgress {
      handleTapWhenShapeIsActive(context: context, point: point, shape: shapeInProgress)
    } else {
      handleTapWhenNoShapeIsActive(context: context, point: point)
    }
  }

  private func handleTapWhenShapeIsActive(context: ToolOperationContext, point: CGPoint, shape: TextShape) {
    if case .delete = editingView.getPointArea(point: point) {
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
      newShape.apply(userSettings: context.userSettings)
      self.shapeInProgress = newShape
      newShape.transform.translation = delegate?.textToolPointForNewText(tappedPoint: point) ?? point
      beginEditing(shape: newShape, context: context)
      updateShapeFrame()
      context.operationStack.apply(operation: AddShapeOperation(shape: newShape))
    }
  }

  public func handleDragStart(context: ToolOperationContext, point: CGPoint) {
    guard let shapeInProgress = shapeInProgress else { return }
    originalTransform = shapeInProgress.transform
    startPoint = point
    if case .resizeAndRotate = editingView.getPointArea(point: point) {
      dragType = .resizeAndRotate
    } else if case .changeWidth = editingView.getPointArea(point: point) {
      dragType = .changeWidth
      originalWidth = shapeInProgress.explicitWidth
      originalBoundingRect = shapeInProgress.boundingRect
      shapeInProgress.explicitWidth = shapeInProgress.explicitWidth ?? shapeInProgress.boundingRect.size.width
    } else if shapeInProgress.hitTest(point: point) {
      dragType = .move
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
      let shape = shapeInProgress,
      let startPoint = startPoint else
    {
      return
    }
    switch dragType {
    case .move:
      let delta = point - startPoint
      shape.transform = originalTransform.translated(by: delta)
      updateTextView()
    case .resizeAndRotate:
      shape.transform = getResizeAndRotateTransform(originalTransform: originalTransform, startPoint: startPoint, point: point, selectedShape: shape)
      updateTextView()
    case .changeWidth:
      let translatedBoundingRect = shape.boundingRect.applying(
        CGAffineTransform(translationX: shape.transform.translation.x,
                          y: shape.transform.translation.y))
      let distanceFromShapeCenter = (point - translatedBoundingRect.middle).length
      let desiredWidthInScreenCoordinates = (distanceFromShapeCenter - editingView.changeWidthControlView.frame.size.width / 2) * 2
      shape.explicitWidth = desiredWidthInScreenCoordinates / shape.transform.scale
      updateShapeFrame()
    case .none:
      // The pan gesture is super finicky at the start, so add an affordance for
      // dragging over a handle
      switch editingView.getPointArea(point: point) {
      case .resizeAndRotate, .changeWidth:
        handleDragStart(context: context, point: point)
      default: break
      }
    }
  }

  public func handleDragEnd(context: ToolOperationContext, point: CGPoint) {
    guard
      let originalTransform = originalTransform,
      let shape = shapeInProgress,
      let startPoint = startPoint else
    {
      return
    }
    switch dragType {
    case .move:
      let delta = CGPoint(x: point.x - startPoint.x, y: point.y - startPoint.y)
      context.operationStack.apply(operation: ChangeTransformOperation(
        shape: shape,
        transform: originalTransform.translated(by: delta),
        originalTransform: originalTransform))
    case .resizeAndRotate:
      context.operationStack.apply(operation: ChangeTransformOperation(
        shape: shape,
        transform: getResizeAndRotateTransform(originalTransform: originalTransform, startPoint: startPoint, point: point, selectedShape: shape),
        originalTransform: originalTransform))
    case .changeWidth:
      shape.explicitWidth = (point - shape.boundingRect.middle).length * 2
      updateTextView()
      context.operationStack.apply(operation: ChangeExplicitWidthOperation(
        shape: shape,
        originalWidth: originalWidth,
        originalBoundingRect: originalBoundingRect,
        newWidth: shape.explicitWidth,
        newBoundingRect: shape.boundingRect))
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
    editingView.textView.text = shape.text
    editingView.textView.font = shape.font
    editingView.textView.textColor = shape.fillColor
    editingView.bounds = shape.boundingRect
    editingView.bounds.size.width += 3
    editingView.transform = CGAffineTransform(
      translationX: -shape.boundingRect.size.width / 2,
      y: -shape.boundingRect.size.height / 2
    ).concatenating(shape.transform.affineTransform)

    editingView.setNeedsLayout()
    editingView.layoutIfNeeded()
  }

  func computeBounds() -> CGRect {
    guard let shape = shapeInProgress else { return .zero }
    updateTextView()

    // Compute rect naively
    var textSize = editingView.sizeThatFits(CGSize(width: shape.explicitWidth ?? maxWidth, height: .infinity))
    if let explicitWidth = shape.explicitWidth {
      textSize.width = explicitWidth
    }
    textSize.width = max(textSize.width, 44)
    let origin = CGPoint(x: -textSize.width / 2, y: -textSize.height / 2)
    var rect = CGRect(origin: origin, size: textSize)

    // If user has explicitly dragged the text width handle, respect their
    // decision and don't try to automatically adjust width
    if shape.explicitWidth != nil {
      return rect
    }

    // Compute rect final position (ignore scale and rotation as a shortcut)
    var transformedRect = rect.applying(CGAffineTransform(translationX: shape.transform.translation.x, y: shape.transform.translation.y))

    // Move rect to the right if it's too far left
    if transformedRect.origin.x < 0 {
      rect.size.width += transformedRect.origin.x
      rect.origin.x -= transformedRect.origin.x
    }

    // Shrink rect if it's too far right
    transformedRect = rect.applying(CGAffineTransform(translationX: shape.transform.translation.x, y: shape.transform.translation.y))
    let widthOverrun = transformedRect.origin.x + transformedRect.size.width - maxWidth
    if widthOverrun > 0 {
      rect.size.width -= widthOverrun
    }

    var finalSize = editingView.sizeThatFits(CGSize(width: rect.size.width, height: .infinity))
    finalSize.width = max(finalSize.width, 44)
    let finalOrigin = CGPoint(x: -finalSize.width / 2, y: -finalSize.height / 2)
    return CGRect(origin: finalOrigin, size: finalSize)
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
    let editingView = TextShapeEditingView(textView: textView)
    delegate?.textToolWillUseEditingView(editingView)
    return editingView
  }
}

extension TextTool: UITextViewDelegate {
  public func textViewDidChange(_ textView: UITextView) {
    guard let shape = shapeInProgress else { return }
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

  /// The text tool is about to present a text editing view. You may configure
  /// it however you like.
  func textToolWillUseEditingView(_ editingView: TextShapeEditingView)
}

// MARK: Interactive view class

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

      changeWidthControlView.widthAnchor.constraint(equalToConstant: 24),
      changeWidthControlView.heightAnchor.constraint(equalToConstant: 24),
      changeWidthControlView.leftAnchor.constraint(equalTo: textView.rightAnchor, constant: 5),
      changeWidthControlView.centerYAnchor.constraint(equalTo: textView.centerYAnchor),
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
    if deleteControlView.convert(deleteControlView.bounds, to: superview!).contains(point) {
      return .delete
    } else if resizeAndRotateControlView.convert(resizeAndRotateControlView.bounds, to: superview!).contains(point) {
      return .resizeAndRotate
    } else if changeWidthControlView.convert(changeWidthControlView.bounds, to: superview!).contains(point) {
      return .changeWidth
    } else {
      return .none
    }
  }
}
