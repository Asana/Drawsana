//
//  ToolOperationContext.swift
//  Drawsana
//
//  Created by Steve Landey on 8/2/18.
//  Copyright © 2018 Asana. All rights reserved.
//

import CoreGraphics

/**
 Aggregate of objects that may be used by tools during operations
 */
public class ToolOperationContext {
  let drawing: Drawing
  let userSettings: UserSettings
  let toolSettings: ToolSettings

  init(
    drawing: Drawing,
    userSettings: UserSettings,
    toolSettings: ToolSettings)
  {
    self.drawing = drawing
    self.userSettings = userSettings
    self.toolSettings = toolSettings
  }
}
