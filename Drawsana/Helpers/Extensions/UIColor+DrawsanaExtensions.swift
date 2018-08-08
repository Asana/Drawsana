//
//  UIColor+DrawsanaExtensions.swift
//  Drawsana
//
//  Created by Steve Landey on 8/7/18.
//  Copyright © 2018 Asana. All rights reserved.
//

import UIKit

extension UIColor {
  convenience init(hexString:String) {
    let hexString = hexString.trimmingCharacters(in: .whitespacesAndNewlines)
    let scanner = Scanner(string: hexString)

    if (hexString.hasPrefix("#")) {
      scanner.scanLocation = 1
    }

    var color: UInt32 = 0
    scanner.scanHexInt32(&color)

    let mask = 0x000000FF
    let r = Int(color >> 16) & mask
    let g = Int(color >> 8) & mask
    let b = Int(color) & mask

    let red   = CGFloat(r) / 255.0
    let green = CGFloat(g) / 255.0
    let blue  = CGFloat(b) / 255.0

    self.init(red:red, green:green, blue:blue, alpha:1)
  }

  var hexString: String {
    var r: CGFloat = 0
    var g: CGFloat = 0
    var b: CGFloat = 0
    var a: CGFloat = 0

    getRed(&r, green: &g, blue: &b, alpha: &a)

    let rgb:Int = (Int)(r*255)<<16 | (Int)(g*255)<<8 | (Int)(b*255)<<0

    return NSString(format:"#%06x", rgb) as String
  }
}
