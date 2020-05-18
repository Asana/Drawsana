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
    var hexString = hexString.trimmingCharacters(in: .whitespacesAndNewlines)

	if hexString.hasPrefix("#") {
		hexString = String(hexString.dropFirst())
	}

	if hexString.lowercased().hasPrefix("0x") {
		hexString = String(hexString.dropFirst(2))
	}

	while hexString.count < 8 {
		hexString.append("F")
	}

    let scanner = Scanner(string: hexString)

    var color: UInt64 = 0

	scanner.scanHexInt64(&color)

    let mask = 0x000000FF
    let r = Int(color >> 24) & mask
    let g = Int(color >> 16) & mask
    let b = Int(color >> 8) & mask
	let a = Int(color) & mask

    let red   = CGFloat(r) / 255.0
    let green = CGFloat(g) / 255.0
    let blue  = CGFloat(b) / 255.0
	let alpha = CGFloat(a) / 255.0

    self.init(red:red, green:green, blue:blue, alpha:alpha)
  }

  var hexString: String {
    var r: CGFloat = 0
    var g: CGFloat = 0
    var b: CGFloat = 0
    var a: CGFloat = 0

    getRed(&r, green: &g, blue: &b, alpha: &a)

    let rgb:Int = (Int)(r*255)<<24 | (Int)(g*255)<<16 | (Int)(b*255)<<8 | (Int)(a*255)

    return NSString(format:"#%08x", rgb) as String
  }
}
