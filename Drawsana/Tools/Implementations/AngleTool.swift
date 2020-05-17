//
//  AngleTool.swift
//  Drawsana
//
//  Created by Thanh Vu on 5/3/19.
//  Copyright © 2019 Asana. All rights reserved.
//

import Foundation

public class AngleTool: DrawingToolForShapeWithThreePoints {
  public override var name: String { return "Angle" }
  public override func makeShape() -> ShapeType {
    let shape = AngleShape()
    return shape
  }
}
