//
//  Bundle.swift
//  MacCast
//
//  Created by Saagar Jha on 1/26/24.
//

import Foundation

extension Bundle {
	var name: String {
		Bundle.main.infoDictionary![kCFBundleNameKey as String] as! String
	}
	
	var version: Int {
		Int(Bundle.main.infoDictionary![kCFBundleVersionKey as String] as! String)!
	}
}
