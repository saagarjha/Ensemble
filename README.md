<p align="center">
<img height="256" src="https://github.com/saagarjha/Ensemble/raw/main/macOS/Assets.xcassets/AppIcon.appiconset/icon_512x512%402x.png" />
</p>

<h1 align="center">Ensemble</h1>

Ensemble (formerly MacCast, before the lawyers had something to say about it) bridges windows from your Mac directly into visionOS, letting you move, resize, and interact with them just like you would with any other native app. It's wireless, like Mac Virtual Display, but without the limitations of resolution or working in a flat plane.

## Status

Ensemble is in alpha and not yet ready for daily use. If you would like to try it out, the easiest way to do so would be to [join the TestFlight](https://testflight.apple.com/join/Pq1HzHqe). However, there are a lot of things I still need to work on and it is likely that the app may break or crash if you push it too hard. Feel free to file bugs if you encounter anything that doesn't work as it should. Do note that I am already tracking some limitations as issues already :)

If you so desire, the app should be fairly straightforward to build yourself using Xcode. It does not require any third-party dependencies (some utility libraries are pulled in using Swift Package Manager). All you probably need to do is to [update the build settings](https://github.com/saagarjha/Ensemble/blob/main/Configs/Deployment.xcconfig) with your signing information. Unfortunately, it is unlikely that I will take any code contributions at the moment as the codebase is not really ready for them. However, if you want to try out your own changes locally or test a recent commit that's not in the release builds yet it's there as an option for you (although I don't expect GitHub and TestFlight to diverge too much, as I have a CI pipeline that synchronizes them).
