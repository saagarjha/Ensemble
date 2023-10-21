//
//  SPI.swift
//  macOS
//
//  Created by Saagar Jha on 10/21/23.
//

import CoreGraphics

typealias CGSConnectionID = CUnsignedInt

let skylight = dlopen("/System/Library/PrivateFrameworks/SkyLight.framework/SkyLight", RTLD_LAZY)
let SLSMainConnectionID = unsafeBitCast(dlsym(skylight, "SLSMainConnectionID"), to: (@convention(c) () -> CGSConnectionID)?.self)!
let SLSCopyAssociatedWindows = unsafeBitCast(dlsym(skylight, "SLSCopyAssociatedWindows"), to: (@convention(c) (CGSConnectionID, CGWindowID) -> CFArray)?.self)!
