//
//  TextTool.swift
//  Drawsana
//
//  Created by Steve Landey on 8/2/18.
//  Copyright © 2018 Asana. All rights reserved.
//

import UIKit

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
  /// it however you like. If you're just starting out, you probably want to
  /// call `editingView.addStandardControls()` to add the delete button and the
  /// two resize handles.
  func textToolWillUseEditingView(_ editingView: TextShapeEditingView)

  /// The user has changed the transform of the selected shape. You may leave
  /// this method empty, but unless you want your text controls to scale with
  /// the text, you'll need to do some math and apply some inverse scaling
  /// transforms here.
  func textToolDidUpdateEditingViewTransform(_ editingView: TextShapeEditingView, transform: ShapeTransform)
}

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
    super.init()
    self.delegate = delegate
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
    context.toolSettings.selectedShape = nil
    finishEditing(context: context)
    selectedShape = nil
  }

  public func handleTap(context: ToolOperationContext, point: CGPoint) {
    if let shapeInProgress = self.selectedShape {
      handleTapWhenShapeIsActive(context: context, point: point, shape: shapeInProgress)
    } else {
      handleTapWhenNoShapeIsActive(context: context, point: point)
    }
  }

  private func handleTapWhenShapeIsActive(context: ToolOperationContext, point: CGPoint, shape: TextShape) {
    if let dragActionType = editingView.getDragActionType(point: point), case .delete = dragActionType {
      applyRemoveShapeOperation(context: context)
      delegate?.textToolDidTapAway(tappedPoint: point)
    } else if shape.hitTest(point: point) {
      // TODO: Forward tap to editingView.textView somehow, or manually set
      // the cursor point
    } else {
      finishEditing(context: context)
      selectedShape = nil
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
      context.operationStack.apply(operation: AddShapeOperation(shape: newShape))
    }
  }

  public func handleDragStart(context: ToolOperationContext, point: CGPoint) {
    guard let shape = selectedShape else { return }
    if let dragActionType = editingView.getDragActionType(point: point), case .resizeAndRotate = dragActionType {
      dragHandler = ResizeAndRotateHandler(shape: shape, textTool: self)
    } else if let dragActionType = editingView.getDragActionType(point: point), case .changeWidth = dragActionType {
      dragHandler = ChangeWidthHandler(shape: shape, textTool: self)
    } else if shape.hitTest(point: point) {
      dragHandler = MoveHandler(shape: shape, textTool: self)
    } else {
      dragHandler = nil
    }

    if let dragHandler = dragHandler {
      applyEditTextOperationIfTextHasChanged(context: context)
      dragHandler.handleDragStart(context: context, point: point)
    }
  }

  public func handleDragContinue(context: ToolOperationContext, point: CGPoint, velocity: CGPoint) {
    if let dragHandler = dragHandler {
      dragHandler.handleDragContinue(context: context, point: point, velocity: velocity)
    } else {
      // The pan gesture is super finicky at the start, so add an affordance for
      // dragging over a handle
      switch editingView.getDragActionType(point: point) {
      case .some(.resizeAndRotate), .some(.changeWidth):
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

  public func apply(context: ToolOperationContext, userSettings: UserSettings) {
    selectedShape?.apply(userSettings: userSettings)
    updateTextView()
    if context.toolSettings.selectedShape == nil {
      selectedShape = nil
      context.toolSettings.interactiveView = nil
    }
    context.toolSettings.isPersistentBufferDirty = true
  }

  // MARK: Helpers: begin/end editing actions

  private func beginEditing(shape: TextShape, context: ToolOperationContext) {
    // Remember values
    originalText = shape.text
    maxWidth = max(maxWidth, context.drawing.size.width)

    // Configure and re-render shape for editing
    shape.isBeingEdited = true // stop rendering this shape while textView is open
    shapeUpdater?.rerenderAllShapesInefficiently()

    // Set selection in an order that guarantees the *initial* selection rect
    // is correct
    selectedShape = shape
    updateShapeFrame()
    context.toolSettings.selectedShape = shape

    // Prepare interactive editing view
    context.toolSettings.interactiveView = editingView
    editingView.becomeFirstResponder()
  }

  /// If shape text has changed, notify operation stack so that undo works
  /// properly
  private func finishEditing(context: ToolOperationContext) {
    applyEditTextOperationIfTextHasChanged(context: context)
    selectedShape?.isBeingEdited = false
    context.toolSettings.interactiveView = nil
    context.toolSettings.isPersistentBufferDirty = true
  }

  private func applyEditTextOperationIfTextHasChanged(context: ToolOperationContext) {
    guard let shape = selectedShape, originalText != shape.text else { return }
    context.operationStack.apply(operation: EditTextOperation(
      shape: shape,
      originalText: originalText,
      text: shape.text))
    originalText = shape.text
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

  // MARK: Other helpers

  func updateShapeFrame() {
    guard let shape = selectedShape else { return }
    shape.boundingRect = computeBounds()
    // Shape jumps a little after editing unless we add this fudge factor
    shape.boundingRect.origin.x += 2
    updateTextView()
  }

  func updateTextView() {
    guard let shape = selectedShape else { return }
    // Resetting text while markedTextRange exists breaks some keyboards.
    if editingView.textView.markedTextRange == nil {
      editingView.textView.text = shape.text
    }
    editingView.textView.font = shape.font
    editingView.textView.textColor = shape.fillColor
    editingView.bounds = shape.boundingRect
    // Fudge factor to make shape and text view line up exactly
    editingView.bounds.size.width += 3
    editingView.transform = CGAffineTransform(
      translationX: -shape.boundingRect.size.width / 2,
      y: -shape.boundingRect.size.height / 2
    ).concatenating(shape.transform.affineTransform)

    delegate?.textToolDidUpdateEditingViewTransform(editingView, transform: shape.transform)

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

    // TODO: These calculations are ultimately inaccurate and need to be
    //       revisited.

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
    if let delegate = delegate {
      delegate.textToolWillUseEditingView(editingView)
    } else {
      editingView.addStandardControls()
    }
    return editingView
  }
}

extension TextTool: UITextViewDelegate {
  public func textViewDidChange(_ textView: UITextView) {
    guard let shape = selectedShape else { return }
    
    if textView.markedTextRange == nil {
      shape.text = textView.text ?? ""
    }
    
    updateShapeFrame()
    // TODO: Only update selection rect here instead of rerendering everything
    shapeUpdater?.rerenderAllShapesInefficiently()
  }

  public func textViewDidBeginEditing(_ textView: UITextView) {
    selectedShape?.isBeingEdited = true
  }

  public func textViewShouldEndEditing(_ textView: UITextView) -> Bool {
    selectedShape?.isBeingEdited = false
    return true
  }
}
