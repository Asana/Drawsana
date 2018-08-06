//
//  DrawingOperationStack.swift
//  Drawsana
//
//  Created by Steve Landey on 8/6/18.
//  Copyright © 2018 Asana. All rights reserved.
//

public class DrawingOperationStack {
  public weak var delegate: DrawingOperationStackDelegate?

  var undoStack = [DrawingOperation]()
  var redoStack = [DrawingOperation]()

  let drawing: Drawing

  public var canUndo: Bool { return !undoStack.isEmpty }
  public var canRedo: Bool { return !redoStack.isEmpty }

  init(drawing: Drawing) {
    self.drawing = drawing
  }

  public func apply(operation: DrawingOperation) {
    undoStack.append(operation)
    redoStack = []
    operation.apply(drawing: drawing)
    delegate?.drawingOperationStackDidApply(self, operation: operation)
  }

  @objc public func undo() {
    guard let operation = undoStack.last else { return }
    operation.revert(drawing: drawing)
    redoStack.append(operation)
    undoStack.removeLast()
    delegate?.drawingOperationStackDidUndo(self, operation: operation)
  }

  @objc public func redo() {
    guard let operation = redoStack.last else { return }
    operation.apply(drawing: drawing)
    undoStack.append(operation)
    redoStack.removeLast()
    delegate?.drawingOperationStackDidRedo(self, operation: operation)
  }
}

public protocol DrawingOperationStackDelegate: AnyObject {
  func drawingOperationStackDidUndo(_ operationStack: DrawingOperationStack, operation: DrawingOperation)
  func drawingOperationStackDidRedo(_ operationStack: DrawingOperationStack, operation: DrawingOperation)
  func drawingOperationStackDidApply(_ operationStack: DrawingOperationStack, operation: DrawingOperation)
}

public protocol DrawingOperation {
  func apply(drawing: Drawing)
  func revert(drawing: Drawing)
}
