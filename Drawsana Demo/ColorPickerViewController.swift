//
//  ColorPickerViewController.swift
//  Drawsana Demo
//
//  Created by Steve Landey on 8/27/18.
//  Copyright © 2018 Asana. All rights reserved.
//

import UIKit

protocol ColorPickerViewControllerDelegate: AnyObject {
  func colorPickerViewControllerDidPick(colorIndex: Int, color: UIColor?, identifier: String)
}

class ColorPickerViewController: UIViewController {
  let colors: [UIColor?]
  weak var delegate: ColorPickerViewControllerDelegate?
  var identifier: String

  init(identifier: String, colors: [UIColor?], delegate: ColorPickerViewControllerDelegate) {
    self.identifier = identifier
    self.colors = colors
    self.delegate = delegate
    super.init(nibName: nil, bundle: nil)
    preferredContentSize = CGSize(width: 44, height: colors.count * (44 + 10) + 10)
  }

  required init?(coder aDecoder: NSCoder) {
    fatalError("init(coder:) has not been implemented")
  }
  
  override func loadView() {
    let stackView = UIStackView(arrangedSubviews: colors.enumerated().map({ (i, color) in
      let button = UIButton()
      button.tag = i
      button.translatesAutoresizingMaskIntoConstraints = false
      button.addTarget(self, action: #selector(ColorPickerViewController.setColor(button:)), for: .touchUpInside)
      button.backgroundColor = color == nil ? .black : color
      if color == nil {
        button.setTitle("✕", for: .normal)
      }

      NSLayoutConstraint.activate([
        button.widthAnchor.constraint(equalToConstant: 44),
        button.heightAnchor.constraint(equalToConstant: 44),
      ])
      return button
    }))

    stackView.axis = .vertical
    stackView.distribution = .equalSpacing
    stackView.alignment = .fill
    self.view = stackView
  }

  @objc private func setColor(button: UIButton) {
    delegate?.colorPickerViewControllerDidPick(
      colorIndex: button.tag, color: colors[button.tag], identifier: identifier)
  }
}
