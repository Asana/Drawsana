//
//  DrawingOperationStack.swift
//  Drawsana
//
//  Created by Steve Landey on 8/6/18.
//  Copyright © 2018 Asana. All rights reserved.
//

import Foundation

/**
 Store and manage the undo/redo stack for a drawing
 */
public class DrawingOperationStack {
  /// You may set a custom delegate for `DrawingOperationStack` if you want to
  /// know when undo/redo are available in realtime. The core framework does not
  /// use this delegate.
  public weak var delegate: DrawingOperationStackDelegate?

  public var canUndo: Bool { return !undoStack.isEmpty }
  public var canRedo: Bool { return !redoStack.isEmpty }

  /// You may inspect the raw values in the undo stack in order to do
  /// fancy-pants things like coalesce operations together.
  public private(set) var undoStack = [DrawingOperation]()
  var redoStack = [DrawingOperation]()

  private let drawing: Drawing

  init(drawing: Drawing) {
    self.drawing = drawing
  }

  /// Add an operation to the stack
  public func apply(operation: DrawingOperation) {
    guard operation.shouldAdd(to: self) else { return }

    undoStack.append(operation)
    redoStack = []
    operation.apply(drawing: drawing)
    delegate?.drawingOperationStackDidApply(self, operation: operation)
  }

  /// Undo the latest operation, if any
  @objc public func undo() {
    guard let operation = undoStack.last else { return }
    operation.revert(drawing: drawing)
    redoStack.append(operation)
    undoStack.removeLast()
    delegate?.drawingOperationStackDidUndo(self, operation: operation)
  }

  /// Redo the most recently undone operation, if any
  @objc public func redo() {
    guard let operation = redoStack.last else { return }
    operation.apply(drawing: drawing)
    undoStack.append(operation)
    redoStack.removeLast()
    delegate?.drawingOperationStackDidRedo(self, operation: operation)
  }

  /// Clear the redo stack
  @objc public func clearRedoStack() {
    redoStack = []
  }
}

public protocol DrawingOperationStackDelegate: AnyObject {
  func drawingOperationStackDidUndo(_ operationStack: DrawingOperationStack, operation: DrawingOperation)
  func drawingOperationStackDidRedo(_ operationStack: DrawingOperationStack, operation: DrawingOperation)
  func drawingOperationStackDidApply(_ operationStack: DrawingOperationStack, operation: DrawingOperation)
}

/**
 All drawing operations must implement this protocol
 */
public protocol DrawingOperation {
  /**
   Return true iff this operation should be added to the undo stack. Default
   implementation returns `true`.

   This method may be used to coalesce operations together. For example, the
   operation to change a text shape's text may coalesce itself with the
   operation to add the text shape to the drawing.
   */
  func shouldAdd(to operationStack: DrawingOperationStack) -> Bool
  func apply(drawing: Drawing)
  func revert(drawing: Drawing)
}
public extension DrawingOperation {
  func shouldAdd(to operationStack: DrawingOperationStack) -> Bool { return true }
}
