//
//  TextTool.swift
//  Drawsana
//
//  Created by Steve Landey on 8/2/18.
//  Copyright © 2018 Asana. All rights reserved.
//

import CoreGraphics
import UIKit

public class TextTool: NSObject, DrawingTool {
  /// MARK: Protocol requirements

  public let isProgressive = false
  public let name: String = "Text"

  // MARK: Public properties

  /// You may set yourself as the delegate to be notified when special selection
  /// events happen that you might want to react to. The core framework does
  /// not use this delegate.
  public weak var delegate: TextToolDelegate?

  // MARK: Internal state

  /// The text tool has 3 different behaviors on drag depending on where your
  /// touch starts. See `DragHandler.swift` for their implementations.
  private var dragHandler: DragHandler?
  private var selectedShape: TextShape?
  private var originalText = ""
  private var maxWidth: CGFloat = 320  // updated from drawing.size
  private weak var shapeUpdater: DrawsanaViewShapeUpdating?
  // internal for use by DragHandler subclasses
  internal lazy var editingView: TextShapeEditingView = makeTextView()

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
    selectedShape = shape
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
    if let shape = selectedShape {
      if originalText != shape.text {
        context.operationStack.apply(operation: EditTextOperation(shape: shape, originalText: originalText, text: shape.text))
        originalText = shape.text
      }

      shape.isBeingEdited = false
      context.toolSettings.isPersistentBufferDirty = true
    }
  }

  private func applyRemoveShapeOperation(context: ToolOperationContext) {
    guard let shape = selectedShape else { return }
    editingView.resignFirstResponder()
    shape.isBeingEdited = false
    context.operationStack.apply(operation: RemoveShapeOperation(shape: shape))
    selectedShape = nil
    context.toolSettings.selectedShape = nil
    context.toolSettings.isPersistentBufferDirty = true
    context.toolSettings.interactiveView = nil
  }

  // MARK: Tool lifecycle

  public func apply(context: ToolOperationContext, userSettings: UserSettings) {
    selectedShape?.apply(userSettings: userSettings)
    updateTextView()
    context.toolSettings.isPersistentBufferDirty = true
  }

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
    if let shapeInProgress = self.selectedShape {
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
      self.selectedShape = nil
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
      self.selectedShape = newShape
      newShape.transform.translation = delegate?.textToolPointForNewText(tappedPoint: point) ?? point
      beginEditing(shape: newShape, context: context)
      updateShapeFrame()
      context.operationStack.apply(operation: AddShapeOperation(shape: newShape))
    }
  }

  public func handleDragStart(context: ToolOperationContext, point: CGPoint) {
    guard let shape = selectedShape else { return }
    if case .resizeAndRotate = editingView.getPointArea(point: point) {
      dragHandler = ResizeAndRotateHandler(shape: shape, textTool: self)
    } else if case .changeWidth = editingView.getPointArea(point: point) {
      dragHandler = ChangeWidthHandler(shape: shape, textTool: self)
    } else if shape.hitTest(point: point) {
      dragHandler = MoveHandler(shape: shape, textTool: self)
    } else {
      dragHandler = nil
    }
    dragHandler?.handleDragStart(context: context, point: point)
  }

  public func handleDragContinue(context: ToolOperationContext, point: CGPoint, velocity: CGPoint) {
    if let dragHandler = dragHandler {
      dragHandler.handleDragContinue(context: context, point: point, velocity: velocity)
    } else {
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
    if let dragHandler = dragHandler {
      dragHandler.handleDragEnd(context: context, point: point)
      self.dragHandler = nil
    }
    context.toolSettings.isPersistentBufferDirty = true
    updateTextView()
  }

  public func handleDragCancel(context: ToolOperationContext, point: CGPoint) {
    if let dragHandler = dragHandler {
      dragHandler.handleDragCancel(context: context, point: point)
      self.dragHandler = nil
    }
  }

  // MARK: Helpers

  func updateShapeFrame() {
    guard let shape = selectedShape else { return }
    shape.boundingRect = computeBounds()
    shape.boundingRect.origin.x += 2
    updateTextView()
  }

  func updateTextView() {
    guard let shape = selectedShape else { return }
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
    guard let shape = selectedShape else { return .zero }
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
    guard let shape = selectedShape else { return }
    shape.text = textView.text ?? ""
    updateShapeFrame()
    shapeUpdater?.shapeDidUpdate(shape: shape)
  }

  public func textViewDidBeginEditing(_ textView: UITextView) {
    selectedShape?.isBeingEdited = true
  }

  public func textViewShouldEndEditing(_ textView: UITextView) -> Bool {
    selectedShape?.isBeingEdited = false
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
