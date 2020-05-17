//
//  DrawingToolForShapeWithTwoPoints.swift
//  Drawsana
//
//  Created by Steve Landey on 8/9/18.
//  Copyright © 2018 Asana. All rights reserved.
//

import CoreGraphics

/**
 Base class for tools (rect, line, ellipse) that are drawn by dragging from
 one point to another
 */
open class DrawingToolForShapeWithTwoPoints: DrawingTool {
  public typealias ShapeType = Shape & ShapeWithTwoPoints

  open var name: String { fatalError("Override me") }

  public var shapeInProgress: ShapeType?

  public var isProgressive: Bool { return false }

  public init() { }

  /// Override this method to return a shape ready to be drawn to the screen.
  open func makeShape() -> ShapeType {
    fatalError("Override me")
  }

  public func handleTap(context: ToolOperationContext, point: CGPoint) {
  }

  public func handleDragStart(context: ToolOperationContext, point: CGPoint) {
    shapeInProgress = makeShape()
    shapeInProgress?.a = point
    shapeInProgress?.b = point
    shapeInProgress?.apply(userSettings: context.userSettings)
  }

  public func handleDragContinue(context: ToolOperationContext, point: CGPoint, velocity: CGPoint) {
    shapeInProgress?.b = point
  }

  public func handleDragEnd(context: ToolOperationContext, point: CGPoint) {
    guard var shape = shapeInProgress else { return }
    shape.b = point
    context.operationStack.apply(operation: AddShapeOperation(shape: shape))
    shapeInProgress = nil
  }

  public func handleDragCancel(context: ToolOperationContext, point: CGPoint) {
    // No such thing as a cancel for this tool. If this was recognized as a tap,
    // just end the shape normally.
    handleDragEnd(context: context, point: point)
  }

  public func renderShapeInProgress(transientContext: CGContext) {
    shapeInProgress?.render(in: transientContext)
  }

  public func apply(context: ToolOperationContext, userSettings: UserSettings) {
    shapeInProgress?.apply(userSettings: userSettings)
    context.toolSettings.isPersistentBufferDirty = true
  }
}
