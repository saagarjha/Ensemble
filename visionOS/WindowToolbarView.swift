//
//  WindowToolbarView.swift
//  visionOS
//
//  Created by Saagar Jha on 3/2/24.
//

import SwiftUI

struct WindowToolbarView: View {
	let title: String
	let icon: Data?

	@Environment(\.openWindow) private var openWindow

	var body: some View {
		HStack {
			if let icon {
				Image(uiImage: UIImage(data: icon)!)
					.resizable()
					.aspectRatio(contentMode: .fit)
					.frame(maxHeight: 64)
					.padding()
			} else {
				Image(systemName: "questionmark.app")
					.resizable()
					.aspectRatio(contentMode: .fit)
					.padding()
			}
			Text("\(title)")
				.font(.title)
				.padding(.trailing)
				.lineLimit(1)
				.fixedSize()
			Divider()
				.padding(.vertical, 20)
			Button(action: {
				openWindow(id: "window")
			}) {
				Image(systemName: "plus")
					.padding()
			}
			.buttonBorderShape(.circle)
			.tint(.clear)
			.padding()
		}
		.glassBackgroundEffect(in: .capsule)
	}
}

#Preview {
	Rectangle()
		.ornament(attachmentAnchor: .scene(.bottom)) {
			WindowToolbarView(title: "Window Title", icon: nil)
		}
}
