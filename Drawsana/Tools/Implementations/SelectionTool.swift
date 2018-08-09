//
//  AMDrawingTool+Text.swift
//  AMDrawingView
//
//  Created by Steve Landey on 7/26/18.
//  Copyright © 2018 Asana. All rights reserved.
//

import UIKit

public protocol SelectionToolDelegate: AnyObject {
  /// User tapped on a shape, but it was already selected. You might want to
  /// take this opportuny to activate a tool that can edit that shape, if one
  /// exists.
  func selectionToolDidTapOnAlreadySelectedShape(_ shape: ShapeSelectable)
}

public class SelectionTool: DrawingTool {
  public let name = "Selection"
  
  public var isProgressive: Bool { return false }

  /// You may set yourself as the delegate to be notified when special selection
  /// events happen that you might want to react to. The core framework does
  /// not use this delegate.
  public weak var delegate: SelectionToolDelegate?

  private var originalTransform: ShapeTransform?
  private var startPoint: CGPoint?

  public init(delegate: SelectionToolDelegate? = nil) {
    self.delegate = delegate
  }

  public func deactivate(context: ToolOperationContext) {
    context.toolSettings.selectedShape = nil
  }

  public func apply(context: ToolOperationContext, userSettings: UserSettings) {
    if let compatibleShape = context.toolSettings.selectedShape as? UserSettingsApplying {
      compatibleShape.apply(userSettings: userSettings)
      context.toolSettings.isPersistentBufferDirty = true
    }
  }

  public func handleTap(context: ToolOperationContext, point: CGPoint) {
    if let selectedShape = context.toolSettings.selectedShape, selectedShape.hitTest(point: point) == true {
      if let delegate = delegate {
        delegate.selectionToolDidTapOnAlreadySelectedShape(selectedShape)
      } else {
        // Default behavior: deselect the shape
        context.toolSettings.selectedShape = nil
      }
      return
    }

    context.toolSettings.selectedShape = context.drawing.shapes
      .compactMap({ $0 as? ShapeSelectable })
      .filter({ $0.hitTest(point: point) })
      .last
  }

  public func handleDragStart(context: ToolOperationContext, point: CGPoint) {
    guard let selectedShape = context.toolSettings.selectedShape, selectedShape.hitTest(point: point) else { return }
    originalTransform = selectedShape.transform
    startPoint = point
  }

  public func handleDragContinue(context: ToolOperationContext, point: CGPoint, velocity: CGPoint) {
    guard
      let originalTransform = originalTransform,
      let selectedShape = context.toolSettings.selectedShape,
      let startPoint = startPoint else
    {
        return
    }
    let delta = CGPoint(x: point.x - startPoint.x, y: point.y - startPoint.y)
    selectedShape.transform = originalTransform.translated(by: delta)
    context.toolSettings.isPersistentBufferDirty = true
  }

  public func handleDragEnd(context: ToolOperationContext, point: CGPoint) {
    guard
      let originalTransform = originalTransform,
      let selectedShape = context.toolSettings.selectedShape,
      let startPoint = startPoint else
    {
      return
    }
    let delta = CGPoint(x: point.x - startPoint.x, y: point.y - startPoint.y)
    context.operationStack.apply(operation: ChangeTransformOperation(
      shape: selectedShape,
      transform: originalTransform.translated(by: delta),
      originalTransform: originalTransform))
    context.toolSettings.isPersistentBufferDirty = true
  }

  public func handleDragCancel(context: ToolOperationContext, point: CGPoint) {
    context.toolSettings.selectedShape?.transform = originalTransform ?? .identity
    context.toolSettings.isPersistentBufferDirty = true
  }
}
