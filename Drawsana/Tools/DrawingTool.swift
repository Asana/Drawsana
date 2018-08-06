//
//  AMDrawingTool.swift
//  AMDrawingView
//
//  Created by Steve Landey on 7/23/18.
//  Copyright © 2018 Asana. All rights reserved.
//

import CoreGraphics

public protocol ToolStateAppliable {
  func apply(state: UserSettings)
}

// MARK: Main protocol

public protocol DrawingTool: ToolStateAppliable {
  var isProgressive: Bool { get }
  var name: String { get }

  func activate(shapeUpdater: DrawsanaViewShapeUpdating, context: ToolOperationContext, shape: Shape?)
  func deactivate(context: ToolOperationContext)

  func handleTap(context: ToolOperationContext, point: CGPoint)
  func handleDragStart(context: ToolOperationContext, point: CGPoint)
  func handleDragContinue(context: ToolOperationContext, point: CGPoint, velocity: CGPoint)
  func handleDragEnd(context: ToolOperationContext, point: CGPoint)
  func handleDragCancel(context: ToolOperationContext, point: CGPoint)

  func apply(state: UserSettings)

  func renderShapeInProgress(transientContext: CGContext)
}
public extension DrawingTool {
  func activate(shapeUpdater: DrawsanaViewShapeUpdating, context: ToolOperationContext, shape: Shape?) { }
  func deactivate(context: ToolOperationContext) { }
  func apply(state: UserSettings) { }
  func renderShapeInProgress(transientContext: CGContext) { }
}

// MARK: Convenience protocol: automatically render shapeInProgress

public protocol ToolWithShapeInProgressRendering {
  associatedtype ShapeType: Shape
  var shapeInProgress: ShapeType? { get }
}
extension ToolWithShapeInProgressRendering {
  public func renderShapeInProgress(transientContext: CGContext) {
    shapeInProgress?.render(in: transientContext)
  }
}

