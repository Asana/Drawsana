//
//  Drawing.swift
//  Drawsana
//
//  Created by Steve Landey on 8/2/18.
//  Copyright © 2018 Asana. All rights reserved.
//

import CoreGraphics

struct AnyEncodable: Encodable {
  let base: Encodable

  func encode(to encoder: Encoder) throws {
    try base.encode(to: encoder)
  }
}

/**
 Stores list of shapes and size of drawing.
 */
public class Drawing: Codable {
  private enum CodingKeys: String, CodingKey {
    case size
    case shapes
  }

  private enum ShapeTypeCodingKey: String, CodingKey {
    case type
  }

  weak var delegate: DrawingDelegate?

  var size: CGSize
  var shapes: [Shape] = []

  init(size: CGSize, delegate: DrawingDelegate? = nil) {
    self.size = size
    self.delegate = delegate
  }

  // MARK: Codable

  public required init(from decoder: Decoder) throws {
    let container = try decoder.container(keyedBy: CodingKeys.self)
    size = try container.decode(CGSize.self, forKey: .size)

    shapes = []
    var shapeIter = try container.nestedUnkeyedContainer(forKey: .shapes)
    while !shapeIter.isAtEnd {
      tryDecodingAllShapes(
        &shapeIter,
        completion: {
          shapes.append(contentsOf: $0.compactMap({ $0 }))
        })
    }
  }

  /**
   If you've defined your own shape class, override this method. Call super(),
   then do this:

   ```swift
   completion([
     tryDecoding(&container, with: MyShape.self)
   ])
   ```
   */
  public func tryDecodingAllShapes(_ container: inout UnkeyedDecodingContainer, completion: ([Shape?]) -> Void) {
    completion([
      tryDecoding(&container, with: EllipseShape.self),
      tryDecoding(&container, with: LineShape.self),
      tryDecoding(&container, with: PenShape.self),
      tryDecoding(&container, with: RectShape.self),
      tryDecoding(&container, with: TextShape.self),
    ])
  }

  public func tryDecoding<T: Shape & Decodable>(_ container: inout UnkeyedDecodingContainer, with type: T.Type) -> T? {
    do {
      return try container.decode(T.self)
    } catch {
      return nil
    }
  }

  public func encode(to encoder: Encoder) throws {
    var container = encoder.container(keyedBy: CodingKeys.self)
    try container.encode(size, forKey: .size)
    try container.encode(shapes.map({ AnyEncodable(base: $0) }), forKey: .shapes)
  }

  // MARK: Operations

  public func add(shape: Shape) {
    shapes.append(shape)
    delegate?.drawingDidAddShape(shape)
  }

  public func update(shape: Shape) {
    delegate?.drawingDidUpdateShape(shape)
  }

  public func remove(shape: Shape) {
    shapes = shapes.filter({ $0 !== shape })
    delegate?.drawingDidRemoveShape(shape)
  }

  public func getShape(at point: CGPoint, filter: ((Shape) -> Bool)? = nil) -> Shape? {
    return shapes.filter({ $0.hitTest(point: point) && filter?($0) != false }).first
  }

  public func getShape<T: Shape>(of type: T.Type, at point: CGPoint, filter: ((Shape) -> Bool)? = nil) -> T? {
    return shapes
      .compactMap({ $0 as? T })
      .filter({ $0.hitTest(point: point) })
      .filter({ filter?($0) != false }).first
  }
}

protocol DrawingDelegate: AnyObject {
  func drawingDidAddShape(_ shape: Shape)
  func drawingDidUpdateShape(_ shape: Shape)
  func drawingDidRemoveShape(_ shape: Shape)
}
