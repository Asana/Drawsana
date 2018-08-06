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
  public weak var delegate: UserSettingsDelegate?

  public var strokeColor: UIColor? {
    didSet { delegate?.userSettings(self, didChangeStrokeColor: strokeColor) }
  }
  public var fillColor: UIColor? {
    didSet { delegate?.userSettings(self, didChangeFillColor: fillColor) }
  }
  public var strokeWidth: CGFloat {
    didSet { delegate?.userSettings(self, didChangeStrokeWidth: strokeWidth) }
  }

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

public protocol UserSettingsDelegate: AnyObject {
  func userSettings(_ userSettings: UserSettings, didChangeStrokeColor strokeColor: UIColor?)
  func userSettings(_ userSettings: UserSettings, didChangeFillColor fillColor: UIColor?)
  func userSettings(_ userSettings: UserSettings, didChangeStrokeWidth strokeWidth: CGFloat)
}
