//
//  DrawsanaTests.swift
//  DrawsanaTests
//
//  Created by Steve Landey on 7/23/18.
//  Copyright © 2018 Asana. All rights reserved.
//

import XCTest
@testable import Drawsana

func getJSON<T: Encodable>(_ e: T) -> Data {
  let encoder = JSONEncoder()
  encoder.outputFormatting = [.prettyPrinted, .sortedKeys]
  return try! encoder.encode(e)
}

let defaultTransform = ShapeTransform(
  translation: CGPoint(x: 3, y: 3),
  rotation: 4,
  scale: 5)

struct DefaultShapes {

  static var line: LineShape {
    let shape = LineShape()
    shape.id = "shape"
    shape.a = CGPoint(x: 1, y: 1)
    shape.b = CGPoint(x: 2, y: 2)
    shape.arrowStyle = .standard
    shape.capStyle = .butt
    shape.dashLengths = [1, 1]
    shape.dashPhase = 1
    shape.joinStyle = .bevel
    shape.strokeColor = .red
    shape.strokeWidth = 10
    shape.transform = defaultTransform
    return shape
  }

  static var rect: RectShape {
    let shape = RectShape()
    shape.id = "shape"
    shape.a = CGPoint(x: 1, y: 1)
    shape.b = CGPoint(x: 2, y: 2)
    shape.capStyle = .butt
    shape.dashLengths = [1, 1]
    shape.dashPhase = 1
    shape.fillColor = .yellow
    shape.joinStyle = .bevel
    shape.strokeColor = .red
    shape.strokeWidth = 10
    shape.transform = defaultTransform
    return shape
  }

  static var text: TextShape {
    let shape = TextShape()
    shape.id = "shape"
    shape.explicitWidth = 100
    shape.fontName = "Helvetica Neue"
    shape.fontSize = 12
    shape.text = "xyzzy"
    shape.fillColor = .yellow
    shape.transform = defaultTransform
    shape.boundingRect = CGRect(x: 1, y: 2, width: 3, height: 4)
    return shape
  }

  static var ellipse: EllipseShape {
    let shape = EllipseShape()
    shape.id = "shape"
    shape.a = CGPoint(x: 1, y: 1)
    shape.b = CGPoint(x: 2, y: 2)
    shape.capStyle = .butt
    shape.dashLengths = [1, 1]
    shape.dashPhase = 1
    shape.fillColor = .yellow
    shape.joinStyle = .bevel
    shape.strokeColor = .red
    shape.strokeWidth = 10
    shape.transform = defaultTransform
    return shape
  }

  static var angle: AngleShape {
    let shape = AngleShape()
    shape.id = "shape"
    shape.a = CGPoint(x: 1, y: 1)
    shape.b = CGPoint(x: 2, y: 2)
    shape.c = CGPoint(x: 20, y: 20)
    shape.capStyle = .butt
    shape.dashLengths = [1, 1]
    shape.dashPhase = 1
    shape.joinStyle = .bevel
    shape.strokeColor = .red
    shape.strokeWidth = 10
    shape.transform = defaultTransform
    return shape
  }

  static var star: StarShape {
    let shape = StarShape()
    shape.id = "shape"
    shape.a = CGPoint(x: 1, y: 1)
    shape.b = CGPoint(x: 2, y: 2)
    shape.capStyle = .butt
    shape.dashLengths = [1, 1]
    shape.dashPhase = 1
    shape.fillColor = .yellow
    shape.joinStyle = .bevel
    shape.strokeColor = .red
    shape.strokeWidth = 10
    shape.transform = defaultTransform
    return shape
  }

  static var ngon: NgonShape {
    let shape = NgonShape(8)
    shape.id = "shape"
    shape.a = CGPoint(x: 1, y: 1)
    shape.b = CGPoint(x: 2, y: 2)
    shape.capStyle = .butt
    shape.dashLengths = [1, 1]
    shape.dashPhase = 1
    shape.fillColor = .yellow
    shape.joinStyle = .bevel
    shape.strokeColor = .red
    shape.strokeWidth = 10
    shape.transform = defaultTransform
    return shape
  }

  static var eraser: PenShape {
    let shape = PenShape()
    shape.id = "shape"
    shape.start = CGPoint(x: 1, y: 1)
    shape.add(segment: PenLineSegment(a: CGPoint(x: 1, y: 1), b: CGPoint(x: 2, y: 2), width: 1))
    shape.add(segment: PenLineSegment(a: CGPoint(x: 2, y: 2), b: CGPoint(x: 3, y: 3), width: 2))
    shape.isFinished = true
    shape.strokeColor = .red
    shape.strokeWidth = 10
    shape.isEraser = true
    return shape
  }

}

class LineShapeTests: XCTestCase {

  func testSerialize() {
    let json = getJSON(DefaultShapes.line)
    let decodedShape = try! JSONDecoder().decode(LineShape.self, from: json)
    XCTAssertEqual(decodedShape.id, "shape")
    XCTAssertEqual(decodedShape.a, CGPoint(x: 1, y: 1))
    XCTAssertEqual(decodedShape.b, CGPoint(x: 2, y: 2))
    XCTAssertEqual(decodedShape.arrowStyle, .standard)
    XCTAssertEqual(decodedShape.capStyle, .butt)
    XCTAssertEqual(decodedShape.dashLengths, [1, 1])
    XCTAssertEqual(decodedShape.dashPhase, 1)
    XCTAssertEqual(decodedShape.joinStyle, .bevel)
    XCTAssertEqual(decodedShape.strokeColor, .red)
    XCTAssertEqual(decodedShape.strokeWidth, 10)
    XCTAssertEqual(decodedShape.transform, defaultTransform)

  }
    
}

class RectShapeTests: XCTestCase {

  func testSerialize() {
    let json = getJSON(DefaultShapes.rect)
    let decodedShape = try! JSONDecoder().decode(RectShape.self, from: json)
    XCTAssertEqual(decodedShape.id, "shape")
    XCTAssertEqual(decodedShape.a, CGPoint(x: 1, y: 1))
    XCTAssertEqual(decodedShape.b, CGPoint(x: 2, y: 2))
    XCTAssertEqual(decodedShape.capStyle, .butt)
    XCTAssertEqual(decodedShape.dashLengths, [1, 1])
    XCTAssertEqual(decodedShape.dashPhase, 1)
    XCTAssertEqual(decodedShape.fillColor, .yellow)
    XCTAssertEqual(decodedShape.joinStyle, .bevel)
    XCTAssertEqual(decodedShape.strokeColor, .red)
    XCTAssertEqual(decodedShape.strokeWidth, 10)
    XCTAssertEqual(decodedShape.transform, defaultTransform)
  }

}

class TextShapeTests: XCTestCase {

  var textShapeWithNoExplicitWidth: TextShape {
    let shape = TextShape()
    shape.id = "shape"
    shape.explicitWidth = nil
    shape.fontName = "Helvetica Neue"
    shape.fontSize = 12
    shape.text = "xyzzy"
    shape.fillColor = .yellow
    shape.transform = defaultTransform
    return shape
  }

  func testSerializeWithExplicitWidthAndBoundingRect() {
    let json = getJSON(DefaultShapes.text)
    let decodedShape = try! JSONDecoder().decode(TextShape.self, from: json)
    XCTAssertEqual(decodedShape.id, "shape")
    XCTAssertEqual(decodedShape.explicitWidth, 100)
    XCTAssertEqual(decodedShape.fontName, "Helvetica Neue")
    XCTAssertEqual(decodedShape.fontSize, 12)
    XCTAssertEqual(decodedShape.text, "xyzzy")
    XCTAssertEqual(decodedShape.fillColor, .yellow)
    XCTAssertEqual(decodedShape.transform, defaultTransform)
    XCTAssertEqual(decodedShape.boundingRect, CGRect(x: 1, y: 2, width: 3, height: 4))
  }

  func testSerializeWithoutExplicitWidthOrBoundingRect() {
    let json = getJSON(textShapeWithNoExplicitWidth)
    let decodedShape = try! JSONDecoder().decode(TextShape.self, from: json)
    XCTAssertEqual(decodedShape.id, "shape")
    XCTAssertEqual(decodedShape.explicitWidth, nil)
    XCTAssertEqual(decodedShape.fontName, "Helvetica Neue")
    XCTAssertEqual(decodedShape.fontSize, 12)
    XCTAssertEqual(decodedShape.text, "xyzzy")
    XCTAssertEqual(decodedShape.fillColor, .yellow)
    XCTAssertEqual(decodedShape.transform, defaultTransform)
    XCTAssertEqual(decodedShape.boundingRect, .zero)
  }

  func testDeserializationFromJSON() {
    let jsonString = """
      {
        "fillColor" : "#000000",
        "fontName" : "Marker Felt",
        "fontSize" : 24,
        "id" : "193B98AC-56A9-4038-9345-30D5BFDCFD84",
        "text" : "Text",
        "transform" : {
          "rotation" : 0,
          "scale" : 1,
          "translation" : [
            103.5,
            110.5
          ]
        },
        "type" : "Text"
      }
      """

    let decodedShape = try! JSONDecoder().decode(
      TextShape.self,
      from: jsonString.data(using: .utf8)!)
    XCTAssertEqual(decodedShape.id, "193B98AC-56A9-4038-9345-30D5BFDCFD84")
    XCTAssertEqual(decodedShape.explicitWidth, nil)
    XCTAssertEqual(decodedShape.fontName, "Marker Felt")
    XCTAssertEqual(decodedShape.fontSize, 24)
    XCTAssertEqual(decodedShape.text, "Text")
    XCTAssertEqual(decodedShape.fillColor, UIColor(hexString: "#000000"))
    XCTAssertEqual(
      decodedShape.transform,
      ShapeTransform(translation: CGPoint(x: 103.5, y: 110.5), rotation: 0, scale: 1))
  }

}

class EllipseShapeTests: XCTestCase {

  func testSerialize() {
    let json = getJSON(DefaultShapes.ellipse)
    let decodedShape = try! JSONDecoder().decode(EllipseShape.self, from: json)
    XCTAssertEqual(decodedShape.id, "shape")
    XCTAssertEqual(decodedShape.a, CGPoint(x: 1, y: 1))
    XCTAssertEqual(decodedShape.b, CGPoint(x: 2, y: 2))
    XCTAssertEqual(decodedShape.capStyle, .butt)
    XCTAssertEqual(decodedShape.dashLengths, [1, 1])
    XCTAssertEqual(decodedShape.dashPhase, 1)
    XCTAssertEqual(decodedShape.fillColor, .yellow)
    XCTAssertEqual(decodedShape.joinStyle, .bevel)
    XCTAssertEqual(decodedShape.strokeColor, .red)
    XCTAssertEqual(decodedShape.strokeWidth, 10)
    XCTAssertEqual(decodedShape.transform, defaultTransform)
  }

}

class AngleShapeTests: XCTestCase {

  func testSerialize() {
    let json = getJSON(DefaultShapes.angle)
    let decodedShape = try! JSONDecoder().decode(AngleShape.self, from: json)
    XCTAssertEqual(decodedShape.id, "shape")
    XCTAssertEqual(decodedShape.a, CGPoint(x: 1, y: 1))
    XCTAssertEqual(decodedShape.b, CGPoint(x: 2, y: 2))
    XCTAssertEqual(decodedShape.c, CGPoint(x: 20, y: 20))
    XCTAssertEqual(decodedShape.capStyle, .butt)
    XCTAssertEqual(decodedShape.dashLengths, [1, 1])
    XCTAssertEqual(decodedShape.dashPhase, 1)
    XCTAssertEqual(decodedShape.joinStyle, .bevel)
    XCTAssertEqual(decodedShape.strokeColor, .red)
    XCTAssertEqual(decodedShape.strokeWidth, 10)
    XCTAssertEqual(decodedShape.transform, defaultTransform)
  }

}

class StarShapeTests: XCTestCase {

  func testSerialize() {
    let json = getJSON(DefaultShapes.star)
    let decodedShape = try! JSONDecoder().decode(StarShape.self, from: json)
    XCTAssertEqual(decodedShape.id, "shape")
    XCTAssertEqual(decodedShape.a, CGPoint(x: 1, y: 1))
    XCTAssertEqual(decodedShape.b, CGPoint(x: 2, y: 2))
    XCTAssertEqual(decodedShape.capStyle, .butt)
    XCTAssertEqual(decodedShape.dashLengths, [1, 1])
    XCTAssertEqual(decodedShape.dashPhase, 1)
    XCTAssertEqual(decodedShape.fillColor, .yellow)
    XCTAssertEqual(decodedShape.joinStyle, .bevel)
    XCTAssertEqual(decodedShape.strokeColor, .red)
    XCTAssertEqual(decodedShape.strokeWidth, 10)
    XCTAssertEqual(decodedShape.transform, defaultTransform)
  }

}

class NgonShapeTests: XCTestCase {

  func testSerialize() {
    let json = getJSON(DefaultShapes.ngon)
    let decodedShape = try! JSONDecoder().decode(NgonShape.self, from: json)
    XCTAssertEqual(decodedShape.id, "shape")
    XCTAssertEqual(decodedShape.sides, 8)
    XCTAssertEqual(decodedShape.a, CGPoint(x: 1, y: 1))
    XCTAssertEqual(decodedShape.b, CGPoint(x: 2, y: 2))
    XCTAssertEqual(decodedShape.capStyle, .butt)
    XCTAssertEqual(decodedShape.dashLengths, [1, 1])
    XCTAssertEqual(decodedShape.dashPhase, 1)
    XCTAssertEqual(decodedShape.fillColor, .yellow)
    XCTAssertEqual(decodedShape.joinStyle, .bevel)
    XCTAssertEqual(decodedShape.strokeColor, .red)
    XCTAssertEqual(decodedShape.strokeWidth, 10)
    XCTAssertEqual(decodedShape.transform, defaultTransform)
  }

}

class PenShapeTests: XCTestCase {

  func testSerialize() {
    let json = getJSON(DefaultShapes.eraser)
    let decodedShape = try! JSONDecoder().decode(PenShape.self, from: json)
    XCTAssertEqual(decodedShape.id, "shape")
    XCTAssertEqual(decodedShape.start, CGPoint(x: 1, y: 1))
    XCTAssertEqual(decodedShape.segments, [
      PenLineSegment(a: CGPoint(x: 1, y: 1), b: CGPoint(x: 2, y: 2), width: 1),
      PenLineSegment(a: CGPoint(x: 2, y: 2), b: CGPoint(x: 3, y: 3), width: 2),
    ])
    XCTAssertEqual(decodedShape.isFinished, true)
    XCTAssertEqual(decodedShape.isEraser, true)
    XCTAssertEqual(decodedShape.strokeColor, .red)
    XCTAssertEqual(decodedShape.strokeWidth, 10)
  }

}

class DrawingTests: XCTestCase {

  func testBasicDecoding() {
    Drawing.debugSerialization = true

    let json = """
      {
        "shapes" : [
          {
            "a" : [
              84,
              70.5
            ],
            "b" : [
              196.5,
              166
            ],
            "id" : "F39E55DA-BF06-4EA1-B324-4C82F71CD3AA",
            "strokeColor" : "#000000",
            "strokeWidth" : 5,
            "type" : "Line"
          }
        ],
        "size" : [
          320,
          240
        ]
      }
      """

    let drawing = try! JSONDecoder().decode(Drawing.self, from: json.data(using: .utf8)!)
    XCTAssertEqual(drawing.shapes.count, 1)
  }

  func testBasicDecodingErrorWithoutDebug() {
    Drawing.debugSerialization = false

    let json = """
      {
        "shapes" : [
          {
            "a" : [
              84,
              70.5
            ],
            "id" : "F39E55DA-BF06-4EA1-B324-4C82F71CD3AA",
            "strokeColor" : "#000000",
            "strokeWidth" : 5,
            "type" : "Line"
          }
        ],
        "size" : [
          320,
          240
        ]
      }
      """

    let drawing = try! JSONDecoder().decode(Drawing.self, from: json.data(using: .utf8)!)
    XCTAssertEqual(drawing.shapes.count, 0)
  }

  func testBasicDecodingErrorWithDebug() {
    Drawing.debugSerialization = true

    let json = """
      {
        "shapes" : [
          {
            "a" : [
              84,
              70.5
            ],
            "id" : "F39E55DA-BF06-4EA1-B324-4C82F71CD3AA",
            "strokeColor" : "#000000",
            "strokeWidth" : 5,
            "type" : "Line"
          }
        ],
        "size" : [
          320,
          240
        ]
      }
      """

    XCTAssertThrowsError(try JSONDecoder().decode(Drawing.self, from: json.data(using: .utf8)!))
  }
}
