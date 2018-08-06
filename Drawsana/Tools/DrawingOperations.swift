//
//  DrawingOperations.swift
//  Drawsana
//
//  Created by Steve Landey on 8/6/18.
//  Copyright © 2018 Asana. All rights reserved.
//

struct AddShapeOperation: DrawingOperation {
  let shape: Shape

  func shouldAdd(to operationStack: DrawingOperationStack) -> Bool {
    return true
  }

  func apply(drawing: Drawing) {
    drawing.add(shape: shape)
  }

  func revert(drawing: Drawing) {
    drawing.remove(shape: shape)
  }
}

struct ChangeTransformOperation: DrawingOperation {
  let shape: ShapeWithTransform
  let transform: ShapeTransform
  let originalTransform: ShapeTransform

  init(shape: ShapeWithTransform, transform: ShapeTransform, originalTransform: ShapeTransform) {
    self.shape = shape
    self.transform = transform
    self.originalTransform = originalTransform
  }

  func shouldAdd(to operationStack: DrawingOperationStack) -> Bool {
    return true
  }

  func apply(drawing: Drawing) {
    shape.transform = transform
    drawing.update(shape: shape)
  }

  func revert(drawing: Drawing) {
    shape.transform = originalTransform
    drawing.update(shape: shape)
  }
}

struct EditTextOperation: DrawingOperation {
  let shape: TextShape
  let originalText: String
  let text: String

  init(
    shape: TextShape,
    originalText: String,
    text: String)
  {
    self.shape = shape
    self.originalText = originalText
    self.text = text
  }

  func shouldAdd(to operationStack: DrawingOperationStack) -> Bool {
    if originalText.isEmpty,
      let addShapeOp = operationStack.undoStack.last as? AddShapeOperation,
      addShapeOp.shape === shape {
      // It's pointless to let the user undo to an empty text shape. By setting
      // the shape text immediately and then declining to be added to the stack,
      // the add-shape operation ends up adding/removing the shape with the
      // correct text on its own.
      shape.text = text
      return false
    } else {
      return true
    }
  }

  func apply(drawing: Drawing) {
    shape.text = text
    drawing.update(shape: shape)
  }

  func revert(drawing: Drawing) {
    shape.text = originalText
    drawing.update(shape: shape)
  }
}
