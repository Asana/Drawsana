//
//  StarTool_PentagonTool_TriangleTool.swift
//  Drawsana
//
//  Created by Madan Gupta on 31/12/18.
//  Copyright © 2018 Asana. All rights reserved.
//

import Foundation

public class StarTool: DrawingToolForShapeWithTwoPoints {
    public override var name: String { return "Star" }
    public override func makeShape() -> ShapeType { return StarShape() }
}

public class PentagonTool: DrawingToolForShapeWithTwoPoints {
    public override var name: String { return "Pentagon" }
    public override func makeShape() -> ShapeType { return NgonShape(5) }
}

public class TriangleTool: DrawingToolForShapeWithTwoPoints {
    public override var name: String { return "Triangle" }
    public override func makeShape() -> ShapeType { return NgonShape(3) }
}


