//
//  AMDrawingTool+Freehand.swift
//  AMDrawingView
//
//  Created by Steve Landey on 7/26/18.
//  Copyright © 2018 Asana. All rights reserved.
//

import UIKit

public class PenTool: DrawingTool {
  public typealias ShapeType = PenShape

  public var name: String { return "Pen" }
  public var shapeInProgress: PenShape?
  public var isProgressive: Bool { return false }
  public var velocityBasedWidth: Bool = false

  private var lastVelocity: CGPoint = .zero
  // The shape is rendered to a buffer so that if the color is transparent,
  // you see one contiguous line instead of a bunch of overlapping line
  // segments.
  private var shapeInProgressBuffer: UIImage?
  private var drawingSize: CGSize = .zero
  private var alpha: CGFloat = 0

  public init() { }

  public func handleTap(context: ToolOperationContext, point: CGPoint) {
  }

  public func handleDragStart(context: ToolOperationContext, point: CGPoint) {
    drawingSize = context.drawing.size
    var white: CGFloat = 0  // ignored
    context.userSettings.strokeColor?.getWhite(&white, alpha: &self.alpha)
    lastVelocity = .zero
    let shape = PenShape()
    shapeInProgress = shape
    shape.start = point
    shape.isFinished = false
    shape.apply(userSettings: context.userSettings)
    shape.strokeColor = shape.strokeColor.withAlphaComponent(1)
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
    if lastPoint != point {
      shape.add(segment: PenLineSegment(a: lastPoint, b: point, width: segmentWidth))
    }
    lastVelocity = velocity
  }

  public func handleDragEnd(context: ToolOperationContext, point: CGPoint) {
    guard let shapeInProgress = shapeInProgress else { return }
    shapeInProgress.isFinished = true
    shapeInProgress.apply(userSettings: context.userSettings)
    context.operationStack.apply(operation: AddShapeOperation(shape: shapeInProgress))
    self.shapeInProgress = nil
    shapeInProgressBuffer = nil
  }

  public func handleDragCancel(context: ToolOperationContext, point: CGPoint) {
    // No such thing as a cancel for this tool. If this was recognized as a tap,
    // just end the shape normally.
    handleDragEnd(context: context, point: point)
  }

  public func renderShapeInProgress(transientContext: CGContext) {
    shapeInProgressBuffer = DrawsanaUtilities.renderImage(size: drawingSize) {
      self.shapeInProgressBuffer?.draw(at: .zero)
      self.shapeInProgress?.renderLatestSegment(in: $0)
    }
    shapeInProgressBuffer?.draw(at: .zero, blendMode: .normal, alpha: alpha)
  }
}

public class EraserTool: PenTool {
  public override var name: String { return "Eraser" }
  public override var isProgressive: Bool { return true }
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

  public override func renderShapeInProgress(transientContext: CGContext) {
    shapeInProgress?.renderLatestSegment(in: transientContext)
  }
}
