//
//  ToolPickerViewController.swift
//  Drawsana Demo
//
//  Created by Steve Landey on 8/27/18.
//  Copyright © 2018 Asana. All rights reserved.
//

import Drawsana
import UIKit

protocol ToolPickerViewControllerDelegate: AnyObject {
  func toolPickerViewControllerDidPick(tool: DrawingTool)
}

class ToolPickerViewController: UIViewController {
  let tools: [DrawingTool]
  weak var delegate: ToolPickerViewControllerDelegate?

  init(tools: [DrawingTool], delegate: ToolPickerViewControllerDelegate) {
    self.tools = tools
    self.delegate = delegate
    super.init(nibName: nil, bundle: nil)
    preferredContentSize = CGSize(width: 90, height: tools.count * (44 + 10) + 10)
  }

  required init?(coder aDecoder: NSCoder) {
    fatalError("init(coder:) has not been implemented")
  }

  override func loadView() {
    let stackView = UIStackView(arrangedSubviews: tools.enumerated().map({ (i, tool) in
      let button = UIButton()
      button.tag = i
      button.translatesAutoresizingMaskIntoConstraints = false
      button.addTarget(self, action: #selector(ToolPickerViewController.setTool(button:)), for: .touchUpInside)
      button.setTitle(tool.name, for: .normal)
      button.setTitleColor(.blue, for: .normal)

      NSLayoutConstraint.activate([
        button.widthAnchor.constraint(equalToConstant: 90),
        button.heightAnchor.constraint(equalToConstant: 44),
        ])
      return button
    }))

    stackView.axis = .vertical
    stackView.distribution = .equalSpacing
    stackView.alignment = .fill
    self.view = stackView
  }

  @objc private func setTool(button: UIButton) {
    delegate?.toolPickerViewControllerDidPick(tool: tools[button.tag])
  }
}

