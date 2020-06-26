#  Drawsana 0.12.0

Drawsana is a generalized framework for making freehand drawing views on iOS. You can
let users scribble over images, add shapes and text, and even make your own tools.

Do you want to let your users mark up images? Are you writing a simple painting app?
Drawsana might work for you!

[Demo source code](https://github.com/Asana/Drawsana/blob/master/Drawsana%20Demo/ViewController.swift)

[Docs](https://asana.github.io/Drawsana)

_Like what you see? [Come work with us!](https://asana.com/jobs/all#)_

## Features

* Built-in tools
  * Pen with line smoothing
  * Eraser
  * Ellipse, rect, line, arrow
  * Selection
  * Text
* Undo/redo
* Drawings are `Codable`, so you can save and load them
* Extensible—make your own shapes and tools without forking the library

![screenshot](https://raw.githubusercontent.com/asana/Drawsana/master/demo.gif)

## Installation

Add `Asana/Drawsana` to your Cartfile and update your project like you would for any other
Carthage framework, or clone the source code and add the project to your workspace.

```
github "Asana/Drawsana" == 0.12.0
```

## Usage

```swift
import Drawsana

class MyViewController: UIViewController {
  let drawsanaView = DrawsanaView()
  let penTool = PenTool()
  
  func viewDidLoad() {
    /* ... */
    drawsanaView.set(tool: penTool)
    drawsanaView.userSettings.strokeWidth = 5
    drawsanaView.userSettings.strokeColor = .blue
    drawsanaView.userSettings.fillColor = .yellow
    drawsanaView.userSettings.fontSize = 24
    drawsanaView.userSettings.fontName = "Marker Felt"
  }
  
  func save() {
    let jsonEncoder = JSONEncoder()
    jsonEncoder.outputFormatting = [.prettyPrinted, .sortedKeys]
    let jsonData = try! jsonEncoder.encode(drawingView.drawing)
    // store jsonData somewhere
  }
  
  func load() {
    let data = // load data from somewhere
    let jsonDecoder = JSONDecoder()
    let drawing = try! jsonDecoder.decode(Drawing.self, from: jsonData)
    drawsanaView.drawing = drawing
  }
  
  func showFinalImage() {
    imageView.image = drawsanaView.render() 
  }
}
```

## Background images

Drawsana does not currently have a way to automatically show an image under your drawing.
We recommend that, like in the example class, you add a `UIImageView` underneath your
`DrawsanaView` and make sure your `DrawsanaView`'s frame matches the image frame. When
it's time to get the final image, use `DrawsanaView.render(over: myImage)`.

## Building docs

```sh
sudo gem install jazzy
make docs
open .docs/index.html

pip install ghp-import
make publish-docs
open https://asana.github.io/Drawsana
```

## Changelog

### 0.12.0
* Undo operations are now accessible outside the framework to enable you to make undoable changes with your own UI.
  - `AddShapeOperation`
  - `RemoveShapeOperation`
  - `ChangeTransformOperation`
  - `EditTextOperation`
  - `ChangeExplicitWidthOperation`
* Fix drawing view not being redrawn after being resized.
* Fix bugs related to color serialization.
* Fix bugs related to text entry.

### 0.11.0

* `DrawingOperationStack.clearRedoStack()` clears all redo operations from the
  redo stack.
* `DrawingToolForShapeWithThreePoints` and 
  `DrawingToolForShapeWithTwoPoints` are declared `open` instead of `public` so
  they can be subclassed.
* `PenShape` now works with the selection tool.
* `DrawsanaView.selectionIndicatorAnchorPointOffset` allows Drawsana to
keep working when you change the anchorPoint.
* `Shape.id` is now settable.
* Fix bug that prevented character input of some languages, including Chinese.
* Fix bugs in gesture recognizer.

### 0.10.0
* Convert to Swift 5
* Fix `NgonShape` and `TextShape` serialization bugs. Old data can't be fixed, but
  new data will be correct.
* Deserialization error reporting is more detailed. Shapes that find a JSON object with
  the correct type will now throw errors instead of causing the whole operation to silently
  fail, as long as you enable `Drawing.debugSerialization`.
* Replacing `DrawingView.drawing` now behaves correctly instead of being unusably
  buggy.
* `PenLineSegment`'s members are now public.
* `ShapeTransform` and `PenLineSegment` are now `Equatable`.

### 0.9.4
* Star, triangle, pentagon, and angle tools
* `DrawsanaView.render()` accepts a `scale` parameter instead of always using zero

### 0.9.2
* Convert to Swift 4.2
* CocoaPods support

### 0.9.1

* `DrawsanaView.selectionIndicatorViewShapeLayer` is exposed, allowing you to more
  easily customize the appearance of the selection indicator
* Changes to `DrawsanaView.selectionIndicatorView`'s style are animated in fewer
  cases, which more closely matches user intent
* Improved text tool use in the demo app

### 0.9.0

Initial release
