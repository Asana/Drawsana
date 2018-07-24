//
//  TextTool.swift
//  Drawsana
//
//  Created by Steve Landey on 8/2/18.
//  Copyright © 2018 Asana. All rights reserved.
//

import CoreGraphics
import UIKit

/*
 Text tool behavior spec:

 # Activate tool without shape, then tap:

 Add text under finger, or at point determined by delegate

 # Activate tool with shape:

 Begin editing shape immediately

 # Tap on text

 */

public protocol TextToolDelegate: AnyObject {
  func textToolPointForNewText(tappedPoint: CGPoint) -> CGPoint
  func textToolDidTapAway(tappedPoint: CGPoint)
}

public class TextTool: NSObject, DrawingTool, UITextViewDelegate {
  public let isProgressive = false
  public let name: String = "Text"
  public weak var delegate: TextToolDelegate?

  public var shapeInProgress: TextShape?

  var originalTransform: ShapeTransform?
  var startPoint: CGPoint?

  private weak var shapeUpdater: DrawsanaViewShapeUpdating?

  public init(delegate: TextToolDelegate? = nil) {
    self.delegate = delegate
    super.init()
  }

  public func activate(shapeUpdater: DrawsanaViewShapeUpdating, context: ToolOperationContext, shape: Shape?) {
    self.shapeUpdater = shapeUpdater
  }

  public func deactivate(context: ToolOperationContext) {
    context.interactiveView?.resignFirstResponder()
    context.interactiveView = nil
  }

  public func handleTap(context: ToolOperationContext, point: CGPoint) {
    if let shapeInProgress = self.shapeInProgress {
      if shapeInProgress.hitTest(point: point) {
        // TODO: forward tap to text view
      } else {
        // TODO: save changes
        self.shapeInProgress = nil
        context.toolState.selectedShape = nil
        context.interactiveView?.resignFirstResponder()
        context.interactiveView = nil
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
      context.drawing.add(shape: newShape)
    }
  }

  private func beginEditing(shape: TextShape, context: ToolOperationContext) {
    context.interactiveView = shape.textView
    context.toolState.selectedShape = shape
    shape.textView.frame = shape.computeFrame()
    shape.textView.text = shape.text
    shape.textView.delegate = self
    shape.textView.becomeFirstResponder()
  }

  public func handleDragStart(context: ToolOperationContext, point: CGPoint) {
    guard let shapeInProgress = shapeInProgress, shapeInProgress.hitTest(point: point) else { return }
    originalTransform = shapeInProgress.transform
    startPoint = point
  }

  public func handleDragContinue(context: ToolOperationContext, point: CGPoint, velocity: CGPoint) {
    guard
      let originalTransform = originalTransform,
      let selectedShape = context.toolState.selectedShape,
      let startPoint = startPoint,
      let shapeInProgress = shapeInProgress else
    {
      return
    }
    let delta = CGPoint(x: point.x - startPoint.x, y: point.y - startPoint.y)
    selectedShape.transform = originalTransform.translated(by: delta)
    context.isPersistentBufferDirty = true
    shapeInProgress.textView.frame = shapeInProgress.computeFrame()
  }

  public func handleDragEnd(context: ToolOperationContext, point: CGPoint) {
    guard
      let originalTransform = originalTransform,
      let selectedShape = context.toolState.selectedShape,
      let startPoint = startPoint,
      let shapeInProgress = shapeInProgress else
    {
      return
    }
    let delta = CGPoint(x: point.x - startPoint.x, y: point.y - startPoint.y)
    selectedShape.transform = originalTransform.translated(by: delta)
    context.isPersistentBufferDirty = true
    shapeInProgress.textView.frame = shapeInProgress.computeFrame()
  }

  public func handleDragCancel(context: ToolOperationContext, point: CGPoint) {
    context.toolState.selectedShape?.transform = originalTransform ?? .identity
    context.isPersistentBufferDirty = true
    shapeInProgress!.textView.frame = shapeInProgress!.computeFrame()
  }

  public func textViewDidChange(_ textView: UITextView) {
    shapeInProgress!.text = textView.text ?? ""
    shapeInProgress!.textView.frame = shapeInProgress!.computeFrame()
    shapeUpdater?.shapeDidUpdate(shape: shapeInProgress!)
  }
}
