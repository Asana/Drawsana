//
//  ToolSettings.swift
//  Drawsana
//
//  Created by Steve Landey on 8/6/18.
//  Copyright © 2018 Asana. All rights reserved.
//

import UIKit

/**
 Collection of properties for use by tools. Unlike `UserSettings`, these
 properties are meant to be set by the tools themselves.
 */
public class ToolSettings {
  weak var delegate: ToolSettingsDelegate?

  /// Shape which should have the selection rect drawn around it. May also be
  /// used by tools to keep track of some "active" shape. (The text tool does
  /// this.)
  public var selectedShape: ShapeSelectable? {
    didSet {
      delegate?.toolSettings(self, didSetSelectedShape: selectedShape)
    }
  }

  /// This view, if non-nil, is added to the view hierarchy above the drawing
  /// so that the user may interact with it. The tool is responsible for
  /// setting its frame.
  public var interactiveView: UIView? {
    didSet {
      delegate?.toolSettings(self, didSetInteractiveView: interactiveView, oldValue: oldValue)
    }
  }

  /// Set this to `true` if you have modified a shape that is already added
  /// to the drawing. `DrawingView` checks it each frame during tool operations
  /// and regenerates its buffer accordingly.
  ///
  /// WARNING: Redrawing the buffer is slow!
  public var isPersistentBufferDirty: Bool {
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

protocol ToolSettingsDelegate: AnyObject {
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
