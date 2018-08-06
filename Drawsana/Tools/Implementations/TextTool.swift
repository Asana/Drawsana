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
  public let isProgressive = false
  public let name: String = "Text"
  public weak var delegate: TextToolDelegate?

  public var shapeInProgress: TextShape?

  var originalTransform: ShapeTransform?
  var startPoint: CGPoint?
  var originalText = ""

  private weak var shapeUpdater: DrawsanaViewShapeUpdating?

  public init(delegate: TextToolDelegate? = nil) {
    self.delegate = delegate
    super.init()
  }

  /// If shape text has changed, notify operation stack so that undo works
  /// properly
  private func applyTextEditingOperation(context: ToolOperationContext) {
    if let shape = shapeInProgress, originalText != shape.text {
      context.operationStack.apply(operation: EditTextOperation(shape: shape, originalText: originalText, text: shape.text))
      originalText = shape.text
    }
  }

  private func beginEditing(shape: TextShape, context: ToolOperationContext) {
    context.toolSettings.interactiveView = shape.textView
    context.toolSettings.selectedShape = shape
    shape.textView.frame = shape.computeFrame()
    shape.textView.text = shape.text
    shape.textView.delegate = self
    shape.textView.becomeFirstResponder()
    originalText = shape.text
  }

  public func activate(shapeUpdater: DrawsanaViewShapeUpdating, context: ToolOperationContext, shape: Shape?) {
    self.shapeUpdater = shapeUpdater
    if let shape = shape as? TextShape {
      self.shapeInProgress = shape
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
      if shapeInProgress.hitTest(point: point) {
        // TODO: forward tap to text view
      } else {
        applyTextEditingOperation(context: context)
        self.shapeInProgress = nil
        context.toolSettings.selectedShape = nil
        context.toolSettings.interactiveView?.resignFirstResponder()
        context.toolSettings.interactiveView = nil
        shapeInProgress.updateCachedImage()
        delegate?.textToolDidTapAway(tappedPoint: point)
      }
      return
    } else if let tappedShape = context.drawing.getShape(of: TextShape.self, at: point) {
      self.shapeInProgress = tappedShape
      beginEditing(shape: tappedShape, context: context)
    } else {
      let newShape = TextShape()
      self.shapeInProgress = newShape
      newShape.transform.translation = delegate?.textToolPointForNewText(tappedPoint: point) ?? point
      beginEditing(shape: newShape, context: context)
      context.operationStack.apply(operation: AddShapeOperation(shape: newShape))
    }
  }

  public func handleDragStart(context: ToolOperationContext, point: CGPoint) {
    guard let shapeInProgress = shapeInProgress, shapeInProgress.hitTest(point: point) else { return }
    originalTransform = shapeInProgress.transform
    startPoint = point
  }

  public func handleDragContinue(context: ToolOperationContext, point: CGPoint, velocity: CGPoint) {
    guard
      let originalTransform = originalTransform,
      let selectedShape = context.toolSettings.selectedShape,
      let startPoint = startPoint,
      let shapeInProgress = shapeInProgress else
    {
      return
    }
    let delta = CGPoint(x: point.x - startPoint.x, y: point.y - startPoint.y)
    selectedShape.transform = originalTransform.translated(by: delta)
    context.toolSettings.isPersistentBufferDirty = true
    shapeInProgress.textView.frame = shapeInProgress.computeFrame()
  }

  public func handleDragEnd(context: ToolOperationContext, point: CGPoint) {
    guard
      let originalTransform = originalTransform,
      let selectedShape = context.toolSettings.selectedShape,
      let startPoint = startPoint,
      let shapeInProgress = shapeInProgress else
    {
      return
    }
    let delta = CGPoint(x: point.x - startPoint.x, y: point.y - startPoint.y)
    context.operationStack.apply(operation: ChangeTransformOperation(
      shape: selectedShape,
      transform: originalTransform.translated(by: delta),
      originalTransform: originalTransform))
    context.toolSettings.isPersistentBufferDirty = true
    shapeInProgress.textView.frame = shapeInProgress.computeFrame()
  }

  public func handleDragCancel(context: ToolOperationContext, point: CGPoint) {
    context.toolSettings.selectedShape?.transform = originalTransform ?? .identity
    context.toolSettings.isPersistentBufferDirty = true
    shapeInProgress!.textView.frame = shapeInProgress!.computeFrame()
  }
}

extension TextTool: UITextViewDelegate {
  public func textViewDidChange(_ textView: UITextView) {
    shapeInProgress!.text = textView.text ?? ""
    shapeInProgress!.textView.frame = shapeInProgress!.computeFrame()
    shapeUpdater?.shapeDidUpdate(shape: shapeInProgress!)
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
