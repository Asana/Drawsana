#  Drawsana

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

* Use a real coordinate system, not whatever Core Graphics is using
* Serialization (Codable)
* Selection tool
  * Apply user styles if they change
* Text tool
  * Color controls (currently only draws black text)
  * Scale gesture
  * Deletion?
  * Rotate gesture
