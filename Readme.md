#  Drawsana

Drawsana is a generalized framework for making freehand drawing views on iOS. You can
let users scribble over images, add shapes and text, and even make your own tools.

[Demo source code](https://github.com/stevelandeyasana/Drawsana/blob/master/Drawsana%20Demo/ViewController.swift)

[Docs](https://stevelandeyasana.github.io/Drawsana)

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

## Installation

Add `Asana/Drawsana` to your Cartfile and update your project like you would for any other
Carthage framework, or clone the source code and add the project to your workspace.

## Usage

```swift
import Drawsana

class MyViewController: UIViewController {
  let drawsanaView = DrawsanaView()
  
  func viewDidLoad() {
    /* ... */
    drawsanaView.tool = PenTool()
    drawsanaView.userSettings.strokeWidth = 5
    drawsanaView.userSettings.strokeColor = .blue
    drawsanaView.userSettings.fillColor = .yellow
    drawsanaView.userSettings.fontSize = 24
    drawsanaView.userSettings.fontName = "Marker Felt""
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
open https://stevelandeyasana.github.io/Drawsana
```
