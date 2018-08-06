//
//  Drawing.swift
//  Drawsana
//
//  Created by Steve Landey on 8/2/18.
//  Copyright © 2018 Asana. All rights reserved.
//

import CoreGraphics

public class Drawing {
  weak var delegate: DrawingDelegate?

  var size: CGSize
  var shapes: [Shape] = []

  init(size: CGSize, delegate: DrawingDelegate? = nil) {
    self.size = size
    self.delegate = delegate
  }

  func add(shape: Shape) {
    shapes.append(shape)
    delegate?.drawingDidAddShape(shape)
  }

  func update(shape: Shape) {
    delegate?.drawingDidUpdateShape(shape)
  }

  func remove(shape: Shape) {
    shapes = shapes.filter({ $0 !== shape })
    delegate?.drawingDidRemoveShape(shape)
  }

  func getShape(at point: CGPoint, filter: ((Shape) -> Bool)? = nil) -> Shape? {
    return shapes.filter({ $0.hitTest(point: point) && filter?($0) != false }).first
  }

  func getShape<T: Shape>(of type: T.Type, at point: CGPoint, filter: ((Shape) -> Bool)? = nil) -> T? {
    return shapes
      .compactMap({ $0 as? T })
      .filter({ $0.hitTest(point: point) })
      .filter({ filter?($0) != false }).first
  }
}

public protocol DrawingDelegate: AnyObject {
  func drawingDidAddShape(_ shape: Shape)
  func drawingDidUpdateShape(_ shape: Shape)
  func drawingDidRemoveShape(_ shape: Shape)
}
