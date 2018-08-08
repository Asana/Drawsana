#  Drawsana

Drawsana is a generalized framework for making freehand drawing views on iOS. You can
let users scribble over images, add shapes and text, and even make your own tools.

[Demo source code](https://github.com/stevelandeyasana/Drawsana/blob/master/Drawsana%20Demo/ViewController.swift)

[Docs](https://stevelandeyasana.github.io/Drawsana)

## Features

### Tools

* Pen with line smoothing
* Eraser
* Ellipse, rect, line, arrow
* Selection
* Text

### More

* Drawings are `Codable`, so you can save and load them
* Write your own tools and shapes without forking the library
* Undo/redo

## Building docs

```sh
sudo gem install jazzy
make docs
open .docs/index.html

pip install ghp-import
make publish-docs
open https://stevelandeyasana.github.io/Drawsana
```
