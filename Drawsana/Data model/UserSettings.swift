//
//  UserSettings.swift
//  Drawsana
//
//  Created by Steve Landey on 8/2/18.
//  Copyright © 2018 Asana. All rights reserved.
//

import UIKit

/**
 Collection of user-settable properties for use by tools when creating new
 shapes.
 */
public class UserSettings {
  weak var delegate: UserSettingsDelegate?

  public var strokeColor: UIColor? {
    didSet {
      guard strokeColor != oldValue else { return }
      delegate?.userSettings(self, didChangeStrokeColor: strokeColor)
    }
  }
  public var fillColor: UIColor? {
    didSet {
      guard fillColor != oldValue else { return }
      delegate?.userSettings(self, didChangeFillColor: fillColor)
    }
  }
  public var strokeWidth: CGFloat {
    didSet {
      guard strokeWidth != oldValue else { return }
      delegate?.userSettings(self, didChangeStrokeWidth: strokeWidth)
    }
  }
  public var fontName: String {
    didSet {
      guard fontName != oldValue else { return }
      delegate?.userSettings(self, didChangeFontName: fontName)
    }
  }
  public var fontSize: CGFloat {
    didSet {
      guard fontSize != oldValue else { return }
      delegate?.userSettings(self, didChangeFontSize: fontSize)
    }
  }

  init(
    strokeColor: UIColor?,
    fillColor: UIColor?,
    strokeWidth: CGFloat,
    fontName: String,
    fontSize: CGFloat)
  {
    self.strokeColor = strokeColor
    self.fillColor = fillColor
    self.strokeWidth = strokeWidth
    self.fontName = fontName
    self.fontSize = fontSize
  }
}

protocol UserSettingsDelegate: AnyObject {
  func userSettings(_ userSettings: UserSettings, didChangeStrokeColor strokeColor: UIColor?)
  func userSettings(_ userSettings: UserSettings, didChangeFillColor fillColor: UIColor?)
  func userSettings(_ userSettings: UserSettings, didChangeStrokeWidth strokeWidth: CGFloat)
  func userSettings(_ userSettings: UserSettings, didChangeFontName fontName: String)
  func userSettings(_ userSettings: UserSettings, didChangeFontSize fontSize: CGFloat)
}
