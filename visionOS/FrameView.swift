//
//  FrameView.swift
//  MacCast
//
//  Created by Saagar Jha on 10/22/23.
//

import SwiftUI

struct FrameView: View {
	let frame: Frame

	var body: some View {
		let (frame, mask) = frame.frame
		ImageBufferView(imageBuffer: frame, enableAcceleration: true)
			.mask {
				ImageBufferView(imageBuffer: mask, enableAcceleration: false)
					.equatable()
			}
	}
}
