//
//  StraightLineTool.swift
//  Drawsana
//
//  Created by Thanh Vu on 5/2/19.
//  Copyright © 2019 Asana. All rights reserved.
//

import CoreGraphics

public class StraightLineTool: DrawingToolForShapeWithTwoPoints {
  public override var name: String { return "StraightLine" }
  public override func makeShape() -> ShapeType {
    let shape = LineShape()
    shape.isStraight = true
    return shape
  }
}
