//
//  Drawing.swift
//  Drawsana
//
//  Created by Steve Landey on 8/2/18.
//  Copyright © 2018 Asana. All rights reserved.
//

import CoreGraphics

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

  public var size: CGSize
  public private(set) var shapes: [Shape] = []

  /**
   You must set this property if you use any shapes other than the built-in ones
   and you also want to use the `Codable` features of Drawsana. It's simple:

   ```swift
   drawingView.drawing.shapeDecoder = {
     $0.tryDecoding(MyShape.self)  // repeat for each custom shape class
   }
   ```

   This is needed because there is no way to use `Decodable` with a dynamic
   list of types.
   */
  public var shapeDecoder: ((MultiDecoder<Shape>) -> Void)?

  public init(size: CGSize) {
    self.size = size
  }

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
      let countBefore = shapes.count
      shapes.append(contentsOf: tryDecodingAllShapes(&shapeIter))
      if shapes.count == countBefore {
        let typeContainer = try shapeIter.nestedContainer(keyedBy: ShapeTypeCodingKey.self)
        let type = try typeContainer.decode(String.self, forKey: .type)
        fatalError("Can't decode shape of type \(type)")
      }
    }
  }

  private func tryDecodingAllShapes(_ container: inout UnkeyedDecodingContainer) -> [Shape] {
    let multiDecoder = MultiDecoder<Shape>(container: &container)
    multiDecoder.tryDecoding(EllipseShape.self)
    multiDecoder.tryDecoding(LineShape.self)
    multiDecoder.tryDecoding(PenShape.self)
    multiDecoder.tryDecoding(RectShape.self)
    multiDecoder.tryDecoding(TextShape.self)
    shapeDecoder?(multiDecoder)
    container = multiDecoder.container
    return multiDecoder.results
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

public enum DrawsanaDecodingError: Error {
  case wrongShapeTypeError
}

// MARK: Codable helpers

/// Wrap any non-concrete `Encodable` type (like a `Shape`) in this class to
/// magically make it work with `container.encode(foo, forKey: .foo)`.
private struct AnyEncodable: Encodable {
  let base: Encodable

  func encode(to encoder: Encoder) throws {
    try base.encode(to: encoder)
  }
}

/// Simple pattern for trying to decode array elements as multiple types.
public class MultiDecoder<ResultType> {
  var container: UnkeyedDecodingContainer
  var results = [ResultType]()

  init(container: inout UnkeyedDecodingContainer) {
    self.container = container
  }

  /// Adds the decoded result to `results` if decoding succeeds, otherwise does
  /// nothing.
  public func tryDecoding<T: Shape>(_ type: T.Type) {
    do {
      results.append(try container.decode(T.self) as! ResultType)
    } catch {
    }
  }
}
