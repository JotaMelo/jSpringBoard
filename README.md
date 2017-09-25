# jSpringBoard

One night in June I has an idea stuck in my mind: how would I implement SpringBoard? And a few months later here we are. **jSpringBoard** is an app that tries to reproduce as best as possible some of the UI and interaction of the ***iOS 10*** SpringBoard, including:

- Dock
- App grid, with reordering, delete, folder creation etc
- Opening apps (if you have them)
- Calendar live icon
- Clock live icon
- Compass live icon which is not a feature of the real SpringBoard but I thought it might be fun
- 3D Touch shortcuts
- Virtual home button (just the home button part of assistive touch)
- Reachability
- Spotlight with voice search
- Today view with Siri App Suggestions and Weather widgets. New widgets can be easily created by making a view controller conform to the `WidgetProviding` protocol.
- A Settings app where you can change the wallpaper and manage the grid: reorder apps, reset to defaults and change app info such as the icon, name, badge and bundle ID.

Click on the image below to see a video of the app in action:

[![jSpringBoard video](http://img.youtube.com/vi/yac-23D5heU/0.jpg)](http://www.youtube.com/watch?v=yac-23D5heU)

## Differences

I tried to make all the UI and animations as close as possible to the real SpringBoard, but there are some places where I couldn't achieve the result I wanted.

First, the app open animation looks wrong specially when closing:

iOS 10 |  jSpringBoard
:-----:|:--------------:
![](https://media.giphy.com/media/26vIeUWzBCy8QcJ7W/giphy.gif)  |  ![](https://media.giphy.com/media/26vIf1cvxtAhHmd5S/giphy.gif)

The Spotlight animation from the Today view is more subtle on the real SpringBoard:

iOS 10 |  jSpringBoard
:-----:|:--------------:
![](https://media.giphy.com/media/3ohhwNbdJmr3LT5Paw/giphy.gif)  |  ![](https://media.giphy.com/media/3ov9k4JSWAocJZnOMw/giphy.gif)

Finally, the folder creation animation also looks different but I think this one is a bit better on my side:

iOS 10 |  jSpringBoard
:-----:|:--------------:
![](https://media.giphy.com/media/l1J9J8cdJaPoLZNyU/giphy.gif)  |  ![](https://media.giphy.com/media/l1J9EfCZFDglArtCg/giphy.gif)

## Author

[Jota Melo](https://jota.pm), jpmfagundes@gmail.com
