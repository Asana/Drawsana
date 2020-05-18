//
//  AMDrawingTool+TwoPointShapes.swift
//  AMDrawingView
//
//  Created by Steve Landey on 7/26/18.
//  Copyright © 2018 Asana. All rights reserved.
//

import Foundation

public class LineTool: DrawingToolForShapeWithTwoPoints {
  public override var name: String { return "Line" }
  public override func makeShape() -> ShapeType { return LineShape() }
}

public class ArrowTool: DrawingToolForShapeWithTwoPoints {
  public override var name: String { return "Arrow" }
  public override func makeShape() -> ShapeType {
    let shape = LineShape()
    shape.arrowStyle = .standard
    return shape
  }
}

public class RectTool: DrawingToolForShapeWithTwoPoints {
  public override var name: String { return "Rectangle" }
  public override func makeShape() -> ShapeType { return RectShape() }
}

public class EllipseTool: DrawingToolForShapeWithTwoPoints {
  public override var name: String { return "Ellipse" }
  public override func makeShape() -> ShapeType { return EllipseShape() }
}
