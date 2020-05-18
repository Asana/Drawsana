//
//  ToolOperationContext.swift
//  Drawsana
//
//  Created by Steve Landey on 8/2/18.
//  Copyright © 2018 Asana. All rights reserved.
//

import Foundation

/**
 Aggregate of objects that may be used by tools during operations
 */
public struct ToolOperationContext {
  public let drawing: Drawing
  public let operationStack: DrawingOperationStack
  public let userSettings: UserSettings
  public let toolSettings: ToolSettings
}
