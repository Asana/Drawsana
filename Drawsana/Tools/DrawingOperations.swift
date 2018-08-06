//
//  DrawingOperations.swift
//  Drawsana
//
//  Created by Steve Landey on 8/6/18.
//  Copyright © 2018 Asana. All rights reserved.
//

struct AddShapeOperation: DrawingOperation {
  let shape: Shape

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

  func apply(drawing: Drawing) {
    shape.transform = transform
    drawing.update(shape: shape)
  }

  func revert(drawing: Drawing) {
    shape.transform = originalTransform
    drawing.update(shape: shape)
  }


}
