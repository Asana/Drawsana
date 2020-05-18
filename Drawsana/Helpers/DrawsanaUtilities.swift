//
//  DrawsanaUtilities.swift
//  Drawsana
//
//  Created by Steve Landey on 8/2/18.
//  Copyright © 2018 Asana. All rights reserved.
//

import CoreGraphics
import UIKit
/**
 Internal utility functions
 */
class DrawsanaUtilities {
  /// Return a width which is smaller when velocity is greater
  class func modulatedWidth(width: CGFloat, velocity: CGPoint, previousVelocity: CGPoint, previousWidth: CGFloat) -> CGFloat {
    let velocityAdjustement: CGFloat = 600.0
    let speed = velocity.length / velocityAdjustement
    let previousSpeed = previousVelocity.length / velocityAdjustement

    let modulated = width / (0.6 * speed + 0.4 * previousSpeed)
    let limited = clamp(value: modulated, min: 0.75 * previousWidth, max: 1.25 * previousWidth)
    let final = clamp(value: limited, min: 0.2*width, max: width)

    return final
  }

  /// Render an image using CoreGraphics
    class func renderImage(size: CGSize, scale:CGFloat = 0.0, _ code: (CGContext) -> Void) -> UIImage? {
    UIGraphicsBeginImageContextWithOptions(size, false, scale)
    guard let context = UIGraphicsGetCurrentContext() else {
      UIGraphicsEndImageContext()
      return nil
    }
    code(context)
    let image = UIGraphicsGetImageFromCurrentImageContext()
    UIGraphicsEndImageContext()
    return image
  }

  /// Constrain a value to some min and max
  class func clamp<T: Comparable>(value: T, min: T, max: T) -> T {
    if (value < min) {
      return min
    }

    if (value > max) {
      return max
    }

    return value
  }
}
