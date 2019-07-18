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

  /// Set to `true` to have decoding throw an error if a shape can't be decoded.
  /// Otherwise, shapes with errors are ignored to avoid degrading user
  /// experience.
  public static var debugSerialization = false

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
    // This initializer is pretty complex because it has to decode a
    // heterogeneous array of shapes.
    let container = try decoder.container(keyedBy: CodingKeys.self)

    // Size is straightforward:
    size = try container.decode(CGSize.self, forKey: .size)

    // For shapes, create an iterator for the container and make the destination
    // array (self.shapes) initially empty
    shapes = []
    var shapeIter = try container.nestedUnkeyedContainer(forKey: .shapes)

    while !shapeIter.isAtEnd {
      // Keep track of count so we can see whether we're unable to decode
      // a shape
      let countBefore = shapes.count

      // Try to decode every single kind of shape using this iterator.
      // Note: this might decode more than one shape, if they happen to occur
      // in the order used in `tryDecodingAllShapes(_:)`.
      do {
        try shapes.append(contentsOf: decodeAllShapes(&shapeIter))
      } catch {
        if Drawing.debugSerialization {
          throw error
        }
      }


      // Decoding failed, so bail out with a helpful error message. We choose
      // to crash here for now, but a custom error enum might be a good idea
      // in the future.
      if shapes.count == countBefore {
        // Use a special CodingKeys enum that only cares about the `type`, so
        // we can report exactly what kind of thing can't be parsed
        let typeContainer = try shapeIter.nestedContainer(keyedBy: ShapeTypeCodingKey.self)
        let type = try typeContainer.decode(String.self, forKey: .type)

        // If in debug mode, this is an error. Otherwise, just ignore it and
        // move on.
        if Drawing.debugSerialization {
          throw DrawsanaDecodingError.unknownShapeTypeError(type)
        }
      }
    }
  }

  private func decodeAllShapes(_ container: inout UnkeyedDecodingContainer) throws -> [Shape] {
    let multiDecoder = MultiDecoder<Shape>(container: &container)
    try multiDecoder.decode(EllipseShape.self)
    try multiDecoder.decode(LineShape.self)
    try multiDecoder.decode(PenShape.self)
    try multiDecoder.decode(RectShape.self)
    try multiDecoder.decode(TextShape.self)
    try multiDecoder.decode(StarShape.self)
    try multiDecoder.decode(NgonShape.self)
    shapeDecoder?(multiDecoder)
    container = multiDecoder.container
    return multiDecoder.results
  }

  public func encode(to encoder: Encoder) throws {
    var container = encoder.container(keyedBy: CodingKeys.self)
    try container.encode(size, forKey: .size)
    // The Swift compiler can't figure out how to encode a heterogeneous array
    // of shapes, so we use this type system trick to turn a confusing "Shape"
    // into a non-confusing "Encodable", and for some reason the Swift compiler
    // accepts this and behaves correctly.
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
  case unknownShapeTypeError(String)
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

  /// Adds the decoded result to `results` if decoding succeeds. If decoding
  /// fails because the shape type doesn't match, do nothing. Throws all other
  /// errors.
  ///
  /// Another way to put it is that this method catches
  /// `DrawsanaDecodingError.wrongShapeTypeError` and
  /// `Swift.DecodingError.valueNotFound`.
  public func decode<T: Shape>(_ type: T.Type) throws {
    do {
      results.append(try container.decode(T.self) as! ResultType)
    } catch Swift.DecodingError.valueNotFound {
      return
    } catch DrawsanaDecodingError.wrongShapeTypeError {
      return
    }
  }
}
