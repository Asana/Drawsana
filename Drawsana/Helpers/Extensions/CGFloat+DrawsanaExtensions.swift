//
//  CGFloat+DrawsanaExtensions.swift
//  Drawsana
//
//  Created by Madan Gupta on 26/12/18.
//  Copyright © 2018 Asana. All rights reserved.
//
import CoreGraphics

extension CGFloat {
    var radians: CGFloat {
        get {
            let b = CGFloat(Double.pi) * self/180
            return b
        }
    }
}
