//
//  UserSettings.swift
//  Drawsana
//
//  Created by Steve Landey on 8/2/18.
//  Copyright © 2018 Asana. All rights reserved.
//

import CoreGraphics

/**
 Collection of user-settable properties for use by tools when creating new
 shapes
 */
public class UserSettings {
  public var strokeColor: UIColor?
  public var fillColor: UIColor?
  public var strokeWidth: CGFloat

  init(
    strokeColor: UIColor?,
    fillColor: UIColor?,
    strokeWidth: CGFloat)
  {
    self.strokeColor = strokeColor
    self.fillColor = fillColor
    self.strokeWidth = strokeWidth
  }
}
