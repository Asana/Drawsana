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

## Building docs

```sh
sudo gem install jazzy
make docs
open .docs/index.html

pip install ghp-import
make publish-docs
open https://stevelandeyasana.github.io/Drawsana
```
