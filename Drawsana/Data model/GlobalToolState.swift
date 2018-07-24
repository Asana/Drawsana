//
//  GlobalToolState.swift
//  Drawsana
//
//  Created by Steve Landey on 8/2/18.
//  Copyright © 2018 Asana. All rights reserved.
//

import CoreGraphics

public class GlobalToolState {
  public var strokeColor: UIColor?
  public var fillColor: UIColor?
  public var strokeWidth: CGFloat
  public var selectedShape: ShapeSelectable? {
    didSet {
      delegate?.toolState(self, didSetSelectedShape: selectedShape)
    }
  }

  public weak var delegate: GlobalToolStateDelegate?

  init(
    strokeColor: UIColor?,
    fillColor: UIColor?,
    strokeWidth: CGFloat,
    selectedShape: ShapeSelectable?)
  {
    self.strokeColor = strokeColor
    self.fillColor = fillColor
    self.strokeWidth = strokeWidth
    self.selectedShape = selectedShape
  }
}

public protocol GlobalToolStateDelegate: AnyObject {
  func toolState(
    _ toolState: GlobalToolState,
    didSetSelectedShape selectedShape: ShapeSelectable?)
}
