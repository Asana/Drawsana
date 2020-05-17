//
//  AMDrawingTool.swift
//  AMDrawingView
//
//  Created by Steve Landey on 7/23/18.
//  Copyright © 2018 Asana. All rights reserved.
//

import CoreGraphics

/**
 All drawing tools must implement this protocol.
 */
public protocol DrawingTool: AnyObject {
  /// If `true`, the shape-in-progress buffer is not cleared at all during
  /// drawing operations. So if you're implementing something like a pen tool,
  /// you only need to draw the tail of the line that hasn't yet been drawn,
  /// and avoid the cost of re-rendering the whole shape as it gets longer.
  var isProgressive: Bool { get }

  /// Arbitrary string identifier. Useful for the demo UI, and potentially
  /// associating icons with each tool.
  var name: String { get }

  /**
   The user has picked this tool in the UI. The default implementation does
   nothing.

   - Parameters:
     - shapeUpdater: An object which you may inform of out-of-band shape updates.
       Normally, `DrawsanaView` only checks for changes during tool operations,
       but some tools (e.g. `TextTool`) make changes based on arbitrary user
       input and need a way to update the selection rect and such.
     - context:
     - shape: Tools may be activate with "initial shapes." One use case for this
       is the selection tool handling a double-tap on a text shape. The UI can
       choose to activate the text tool and immediately enter the edit state.
   */
  func activate(shapeUpdater: DrawsanaViewShapeUpdating, context: ToolOperationContext, shape: Shape?)

  /// This tool has become deselected. The default implementation does nothing.
  func deactivate(context: ToolOperationContext)

  /// User tapped on the drawing
  func handleTap(context: ToolOperationContext, point: CGPoint)

  /// User has started to drag on the drawing
  func handleDragStart(context: ToolOperationContext, point: CGPoint)

  /// User has continued to drag on the drawing
  func handleDragContinue(context: ToolOperationContext, point: CGPoint, velocity: CGPoint)

  /// User has stopped to drag on the drawing
  func handleDragEnd(context: ToolOperationContext, point: CGPoint)

  /// The drag gesture has canceled for some reason. The intended use case is
  /// for when the user places a second finger down, and this becomes a pinch
  /// instead of a drag.
  ///
  /// You probably want to clean up all in-progress updates and reset to a state
  /// as if the drag had never begun.
  func handleDragCancel(context: ToolOperationContext, point: CGPoint)

  /// User settings have changed. Update any local state or the shape, if
  /// relevant. The default implementation does nothing.
  func apply(context: ToolOperationContext, userSettings: UserSettings)

  /// After each invocation of `handleDragStart(context:point:)`,
  /// `handleDragContinue(context:point:velocity:)`, and
  /// `handleDragEnd(context:point:)`, this method is called. If your tool is
  /// in the process of creating a shape but it isn't yet committed to the
  /// drawing, render it to this `CGContext`.
  ///
  /// If `isProgressive` is `true`, you only need to render changes since the
  /// last call. Otherwise, you need to render the whole shape.
  ///
  /// The default implementation does nothing.
  func renderShapeInProgress(transientContext: CGContext)
}
// TODO: Should we put these in a base class instead? Do they prevent subclass
// method overrides from being used in practice?
public extension DrawingTool {
  func activate(shapeUpdater: DrawsanaViewShapeUpdating, context: ToolOperationContext, shape: Shape?) { }
  func deactivate(context: ToolOperationContext) { }
  func apply(context: ToolOperationContext, userSettings: UserSettings) { }
  func renderShapeInProgress(transientContext: CGContext) { }
}
