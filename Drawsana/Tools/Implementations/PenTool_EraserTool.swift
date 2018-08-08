//
//  AMDrawingTool+Freehand.swift
//  AMDrawingView
//
//  Created by Steve Landey on 7/26/18.
//  Copyright © 2018 Asana. All rights reserved.
//

import CoreGraphics

public class PenTool: DrawingTool, DrawingToolWithShapeInProgressRendering {
  public typealias ShapeType = PenShape

  public var name: String { return "Pen" }

  public var shapeInProgress: PenShape?

  public var isProgressive: Bool { return true }

  private var lastVelocity: CGPoint = .zero

  public var velocityBasedWidth: Bool = true

  public init() { }

  public func handleTap(context: ToolOperationContext, point: CGPoint) {
    let shape = PenShape()
    shape.start = point
    shape.isFinished = false
    shape.apply(userSettings: context.userSettings)
    context.operationStack.apply(operation: AddShapeOperation(shape: shape))
  }

  public func handleDragStart(context: ToolOperationContext, point: CGPoint) {
    lastVelocity = .zero
    shapeInProgress = PenShape()
    shapeInProgress?.start = point
    shapeInProgress?.apply(userSettings: context.userSettings)
  }

  public func handleDragContinue(context: ToolOperationContext, point: CGPoint, velocity: CGPoint) {
    guard let shape = shapeInProgress else { return }
    let lastPoint = shape.segments.last?.b ?? shape.start
    let segmentWidth: CGFloat

    if velocityBasedWidth {
      segmentWidth = DrawsanaUtilities.modulatedWidth(
        width: shape.strokeWidth,
        velocity: velocity,
        previousVelocity: lastVelocity,
        previousWidth: shape.segments.last?.width ?? shape.strokeWidth)
    } else {
      segmentWidth = shape.strokeWidth
    }
    shape.add(segment: PenLineSegment(a: lastPoint, b: point, width: segmentWidth))
    lastVelocity = velocity
  }

  public func handleDragEnd(context: ToolOperationContext, point: CGPoint) {
    shapeInProgress?.isFinished = true
    context.operationStack.apply(operation: AddShapeOperation(shape: shapeInProgress!))
    shapeInProgress = nil
  }

  public func handleDragCancel(context: ToolOperationContext, point: CGPoint) {
    shapeInProgress = nil
  }

  public func renderShapeInProgress(transientContext: CGContext) {
    shapeInProgress?.renderLatestSegment(in: transientContext)
  }
}

public class EraserTool: PenTool {
  public override var name: String { return "Eraser" }
  public override init() {

    super.init()
    velocityBasedWidth = false
  }

  public override func handleTap(context: ToolOperationContext, point: CGPoint) {
    super.handleTap(context: context, point: point)
    shapeInProgress?.isEraser = true
  }

  public override func handleDragStart(context: ToolOperationContext, point: CGPoint) {
    super.handleDragStart(context: context, point: point)
    shapeInProgress?.isEraser = true
  }
}
