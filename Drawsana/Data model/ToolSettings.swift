//
//  ToolSettings.swift
//  Drawsana
//
//  Created by Steve Landey on 8/6/18.
//  Copyright © 2018 Asana. All rights reserved.
//

import CoreGraphics

/**
 Collection of properties for use by tools. Unlike `UserSettings`, these
 properties are meant to be set by the tools themselves.
 */
public class ToolSettings {
  public weak var delegate: ToolSettingsDelegate?

  public var selectedShape: ShapeSelectable? {
    didSet {
      delegate?.toolSettings(self, didSetSelectedShape: selectedShape)
    }
  }

  var interactiveView: UIView? {
    didSet {
      delegate?.toolSettings(self, didSetInteractiveView: interactiveView, oldValue: oldValue)
    }
  }

  var isPersistentBufferDirty: Bool {
    didSet {
      delegate?.toolSettings(self, didSetIsPersistentBufferDirty: isPersistentBufferDirty)
    }
  }

  init(selectedShape: ShapeSelectable?, interactiveView: UIView?, isPersistentBufferDirty: Bool) {
    self.selectedShape = selectedShape
    self.interactiveView = interactiveView
    self.isPersistentBufferDirty = isPersistentBufferDirty
  }
}

public protocol ToolSettingsDelegate: AnyObject {
  func toolSettings(
    _ toolSettings: ToolSettings,
    didSetSelectedShape selectedShape: ShapeSelectable?)

  func toolSettings(
    _ toolSettings: ToolSettings,
    didSetInteractiveView interactiveView: UIView?,
    oldValue: UIView?)

  func toolSettings(
    _ toolSettings: ToolSettings,
    didSetIsPersistentBufferDirty isPersistentBufferDirty: Bool)
}
