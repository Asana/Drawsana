#  Drawsana

Drawsana is a generalized framework for making freehand drawing views on iOS. You can
let users scribble over images, add shapes and text, and even make your own tools.

[View demo](https://github.com/stevelandeyasana/Drawsana/blob/master/Drawsana%20Demo/ViewController.swift)

## Building docs

```sh
sudo gem install jazzy
make docs
open .docs/index.html

pip install ghp-import
make publish-docs
open https://stevelandeyasana.github.io/Drawsana
```

## To do

* Serialization (Codable)
* Selection tool
  * Apply user styles if they change
