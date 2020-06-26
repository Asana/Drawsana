//
//  AMDrawingView.swift
//  AMDrawingView
//
//  Created by Steve Landey on 7/23/18.
//  Copyright © 2018 Asana. All rights reserved.
//

import UIKit

public let DRAWSANA_VERSION = "0.12.0"

/// Set yourself as the `DrawsanaView`'s delegate to be notified when the active
/// tool changes.
public protocol DrawsanaViewDelegate: AnyObject {
  func drawsanaView(_ drawsanaView: DrawsanaView, didSwitchTo tool: DrawingTool)
  func drawsanaView(_ drawsanaView: DrawsanaView, didStartDragWith tool: DrawingTool)
  func drawsanaView(_ drawsanaView: DrawsanaView, didEndDragWith tool: DrawingTool)
  func drawsanaView(_ drawsanaView: DrawsanaView, didChangeStrokeColor strokeColor: UIColor?)
  func drawsanaView(_ drawsanaView: DrawsanaView, didChangeFillColor fillColor: UIColor?)
  func drawsanaView(_ drawsanaView: DrawsanaView, didChangeStrokeWidth strokeWidth: CGFloat)
  func drawsanaView(_ drawsanaView: DrawsanaView, didChangeFontName fontName: String)
  func drawsanaView(_ drawsanaView: DrawsanaView, didChangeFontSize fontSize: CGFloat)
}

/**
 Add this view to your view hierarchy to get going with Drawsana!
 */
public class DrawsanaView: UIView {
  // MARK: Public API

  public weak var delegate: DrawsanaViewDelegate?

  /// Currently active tool
  public private(set) var tool: DrawingTool?

  /// You may set this object's properties and they will be forwarded to the
  /// active tool and applied to new shapes.
  public let userSettings = UserSettings(
    strokeColor: .blue,
    fillColor: .yellow,
    strokeWidth: 20,
    fontName: "Helvetica Neue",
    fontSize: 24)

  /// Values used by tools to manage state.
  public let toolSettings = ToolSettings(
    selectedShape: nil,
    interactiveView: nil,
    isPersistentBufferDirty: false)

  public var drawing: Drawing = Drawing(size: CGSize(width: 320, height: 320)) {
    didSet {
      tool?.deactivate(context: self.toolOperationContext)
      operationStack = DrawingOperationStack(drawing: drawing)
      drawing.delegate = self
      drawing.size = bounds.size
      tool?.activate(shapeUpdater: self, context: self.toolOperationContext, shape: nil)
      applyToolSettingsChanges()
      if let tool = tool {
        delegate?.drawsanaView(self, didSwitchTo: tool)
      }
      redrawAbsolutelyEverything()
    }
  }

  /// Manages the undo stack. You may become this object's delegate
  /// (`DrawingOperationStackDelegate`) to be notified when undo/redo become
  /// enabled/disabled.
  public lazy var operationStack: DrawingOperationStack = {
    return DrawingOperationStack(drawing: drawing)
  }()

  private var toolOperationContext: ToolOperationContext {
    return ToolOperationContext(
      drawing: drawing,
      operationStack: operationStack,
      userSettings: userSettings,
      toolSettings: toolSettings)
  }

  /// Configurable inset for the selection indicator
  public var selectionIndicatorInset = CGPoint(x: -4, y: -4)

  // MARK: Buffers

  /**
   All "finished" shapes are rendered together to this buffer. If no tool
   operation is active, this is the image that is displayed.
   */
  private var persistentBuffer: UIImage?

  /**
   When a tool operation begins, `persistentBuffer` is copied to this buffer.
   It represents the state of the drawing as the tool operation does its work.

   If the active tool is "progressive," then
   `transientBufferWithShapeInProgress` is copied back to this buffer after each
   display frame. Otherwise, it is not. The result is that simple brushes just
   have to draw the newest fragment of a shape, and other tools like ellipse
   or rect can redraw the whole shape without leaving a trail behind them.
   */
  private var transientBuffer: UIImage?

  /**
   During tool operations, this buffer contains a rendering of the shape in
   progress, over top of the latest contents of `transientBuffer`.

   If the active tool is "progressive," this buffer is always copied back onto
   `transientBuffer` every display frame.

   If a tool operation is active, this is the image that is displayed.
   */
  private var transientBufferWithShapeInProgress: UIImage?

  // MARK: Views

  private let drawingContentView = UIView()

  /// View which is moved around to match the frame of the selected shape.
  /// You may configure whatever properties you want to to make it look like
  /// you want it to look.
  public let selectionIndicatorView = UIView()
    

  /// Offset for the selection Indicatior, because it is placed relative to the anchorPoint.
  /// You should only have to change this if your anchorPoint is different from the default (0.5, 0.5)
  public var selectionIndicatorAnchorPointOffset = CGPoint(x: 0.5, y: 0.5)

  /// Layer that backs `DrawsanaView.selectionIndicatorView`. You may set this
  /// layer's properties to change its visual apparance. Its `path` and `frame`
  /// properties are managed by `DrawsanaView`.
  public var selectionIndicatorViewShapeLayer: CAShapeLayer {
    return selectionIndicatorView.layer.sublayers!.compactMap({ $0 as? CAShapeLayer }).first!
  }

  private let interactiveOverlayContainerView = UIView()

  // MARK: Init

  public override init(frame: CGRect) {
    super.init(frame: frame)
    commonInit()
  }

  required public init?(coder aDecoder: NSCoder) {
    super.init(coder: aDecoder)
    commonInit()
  }

  private func commonInit() {
    backgroundColor = .clear
    drawing.delegate = self
    toolSettings.delegate = self
    userSettings.delegate = self
    isUserInteractionEnabled = true
    clipsToBounds = true

    layer.actions = [
      "contents": NSNull(),
    ]
    selectionIndicatorView.layer.actions = [
      "transform": NSNull(),
      "lineWidth": NSNull(),
      "lineDashPattern": NSNull(),
      "cornerRadius": NSNull(),
    ]

    addSubview(drawingContentView)
    addSubview(selectionIndicatorView)
    addSubview(interactiveOverlayContainerView)

    drawingContentView.translatesAutoresizingMaskIntoConstraints = false
    NSLayoutConstraint.activate([
      drawingContentView.leftAnchor.constraint(equalTo: leftAnchor),
      drawingContentView.rightAnchor.constraint(equalTo: rightAnchor),
      drawingContentView.topAnchor.constraint(equalTo: topAnchor),
      drawingContentView.bottomAnchor.constraint(equalTo: bottomAnchor),
    ])

    interactiveOverlayContainerView.translatesAutoresizingMaskIntoConstraints = false
    NSLayoutConstraint.activate([
      interactiveOverlayContainerView.leftAnchor.constraint(equalTo: leftAnchor),
      interactiveOverlayContainerView.rightAnchor.constraint(equalTo: rightAnchor),
      interactiveOverlayContainerView.topAnchor.constraint(equalTo: topAnchor),
      interactiveOverlayContainerView.bottomAnchor.constraint(equalTo: bottomAnchor),
    ])

    selectionIndicatorView.translatesAutoresizingMaskIntoConstraints = true
    // This autoresizing mask makes selection indincator positionign work
    // correctly. It's not clear why, though, since we're explicitly positioning
    // and transforming the view outside of AutoLayout.
    selectionIndicatorView.autoresizingMask = [.flexibleWidth, .flexibleHeight]

    let selectionLayer = CAShapeLayer()
    selectionLayer.strokeColor = UIColor.black.cgColor
    selectionLayer.lineWidth = 2
    selectionLayer.lineDashPattern = [4, 4]
    selectionLayer.fillColor = nil
    selectionLayer.frame = selectionIndicatorView.bounds
    selectionLayer.path = UIBezierPath(rect: selectionIndicatorView.bounds).cgPath
    selectionIndicatorView.layer.addSublayer(selectionLayer)
    selectionIndicatorView.layer.shadowColor = UIColor.white.cgColor
    selectionIndicatorView.layer.shadowOffset = .zero
    selectionIndicatorView.layer.shadowRadius = 1
    selectionIndicatorView.layer.shadowOpacity = 1
    selectionIndicatorView.isHidden = true

    let panGR = ImmediatePanGestureRecognizer(target: self, action: #selector(didPan(sender:)))
    addGestureRecognizer(panGR)
  }

  public override func layoutSubviews() {
    super.layoutSubviews()
    drawing.size = frame.size

    // Buffers may not be sized correctly
    redrawAbsolutelyEverything()
  }

  // MARK: API

  /// Set the active tool to a new value. If you pass `shape`, it is passed on
  /// to the tool's `DrawingTool.activate(context:shape:)` method.
  public func set(tool: DrawingTool, shape: Shape? = nil) {
    if let oldTool = self.tool, tool === oldTool {
      return
    }
    DispatchQueue.main.async {
      // TODO: why does this break everything if run in the same run loop? Maybe because autoreleasepool?
      self.tool?.deactivate(context: self.toolOperationContext)
      self.tool = tool
      tool.activate(shapeUpdater: self, context: self.toolOperationContext, shape: shape)
      self.applyToolSettingsChanges()
      self.delegate?.drawsanaView(self, didSwitchTo: tool)
    }
  }

  /// Render the drawing on top of an image, using that image's size. Shapes are
  /// re-scaled to match the resolution of the target without artifacts.
  /// The scale parameter defines wether image is rendered at the device's native resolution (scale = 0.0)
  /// or to scale it to the image size (scale 1.0). Use scale = 0.0 when rendering to display on screen and
  /// 1.0 if you are saving the image to a file
    public func render(over image: UIImage?, scale:CGFloat = 0.0) -> UIImage? {
    let size = image?.size ?? drawing.size
    let shapesImage = render(size: size, scale: scale)
    return DrawsanaUtilities.renderImage(size: size, scale: scale) { (context: CGContext) -> Void in
      image?.draw(at: .zero)
      shapesImage?.draw(at: .zero)
    }
  }

  /// Render the drawing. If you pass a size, shapes are re-scaled to be full
  /// resolution at that size, otherwise the view size is used.
    public func render(size: CGSize? = nil, scale:CGFloat = 0.0) -> UIImage? {
    let size = size ?? drawing.size
        return DrawsanaUtilities.renderImage(size: size, scale:scale) { (context: CGContext) -> Void in
      context.saveGState()
      context.scaleBy(
        x: size.width / self.drawing.size.width,
        y: size.height / self.drawing.size.height)
      for shape in self.drawing.shapes {
        shape.render(in: context)
      }
      context.restoreGState()
    }
  }

  // MARK: Gesture recognizers

  @objc private func didPan(sender: ImmediatePanGestureRecognizer) {
    autoreleasepool { _didPan(sender: sender) }
  }

  private func _didPan(sender: ImmediatePanGestureRecognizer) {
    guard let tool = tool else { return }

    let updateUncommittedShapeBuffers: () -> Void = {
      self.transientBufferWithShapeInProgress = DrawsanaUtilities.renderImage(size: self.drawing.size) {
        self.transientBuffer?.draw(at: .zero)
        self.tool?.renderShapeInProgress(transientContext: $0)
      }
      self.drawingContentView.layer.contents = self.transientBufferWithShapeInProgress?.cgImage
      if self.tool?.isProgressive == true {
        self.transientBuffer = self.transientBufferWithShapeInProgress
      }
    }

    let point = sender.location(in: self)
    switch sender.state {
    case .began:
      if let persistentBuffer = persistentBuffer, let cgImage = persistentBuffer.cgImage {
        transientBuffer = UIImage(
          cgImage: cgImage,
          scale: persistentBuffer.scale,
          orientation: persistentBuffer.imageOrientation)
      } else {
        transientBuffer = nil
      }
      tool.handleDragStart(context: toolOperationContext, point: point)
      delegate?.drawsanaView(self, didStartDragWith: tool)
      updateUncommittedShapeBuffers()
    case .changed:
      tool.handleDragContinue(context: toolOperationContext, point: point, velocity: sender.velocity ?? .zero)
      updateUncommittedShapeBuffers()
    case .ended:
      if sender.hasExceededTapThreshold {
        tool.handleDragEnd(context: toolOperationContext, point: point)
        delegate?.drawsanaView(self, didEndDragWith: tool)
      } else {
        tool.handleDragCancel(context: toolOperationContext, point: point)
        tool.handleTap(context: toolOperationContext, point: point)
      }
      reapplyLayerContents()
    case .failed, .cancelled:
      tool.handleDragCancel(context: toolOperationContext, point: point)
      reapplyLayerContents()
    case .possible:
      break // do nothing
    @unknown default:
      break
    }

    applyToolSettingsChanges()
  }

  // MARK: Making stuff show up

  /// If a tool made changes to toolSettings to notify us that the buffer needs
  /// to be redrawn or the selection has moved, act on those changes
  private func applyToolSettingsChanges() {
    if toolSettings.isPersistentBufferDirty {
      redrawAbsolutelyEverything()
      toolSettings.isPersistentBufferDirty = false
    }
    applySelectionViewState()
  }

  private func reapplyLayerContents() {
    self.drawingContentView.layer.contents = persistentBuffer?.cgImage
  }

  private func applySelectionViewState() {
    guard let shape = toolSettings.selectedShape else {
      selectionIndicatorView.isHidden = true
      return
    }

    // Warning: hand-wavy math ahead

    // First, get the size and bounding rect position of the selected shape
    var selectionBounds = shape.boundingRect.insetBy(
      dx: selectionIndicatorInset.x,
      dy: selectionIndicatorInset.y)
    let offset = selectionBounds.origin

    // Next, we're going to remove the position from the bounding rect so we
    // can use it as UIView.bounds.
    selectionBounds.origin = .zero
    selectionIndicatorView.bounds = selectionBounds

    /**
     Now for the hand-wavy part. We're positioning a UIView using `transform`
     and `bounds`, NOT `frame`! It is not valid to set both `transform` and
     `frame` at the same time. (https://developer.apple.com/documentation/uikit/uiview/1622459-transform)

     Unfortunately, this means that we're now positioning relative to the
     parent layer's anchor point at (0.5, 0.5) in the middle of the view,
     rather than the upper left of the view.

     Shapes are positioned using BOTH `boundingRect` AND `transform`! So we need
     to add `offset` from above with `shape.transform.translation` to arrive
     at the right final translation.
     */
    selectionIndicatorView.transform = ShapeTransform(
      translation: (
        // figure out where the shape is in space
        offset + shape.transform.translation +
        // Account for the coordinate system being anchored in the middle
        CGPoint(x: -bounds.size.width * selectionIndicatorAnchorPointOffset.x, y: -bounds.size.height * selectionIndicatorAnchorPointOffset.y) +
        // We've just moved the CENTER of the selection view to the UPPER LEFT
        // of the shape, so adjust by half the selection size:
        CGPoint(x: selectionBounds.size.width / 2, y: selectionBounds.size.height / 2)),
      rotation: shape.transform.rotation,
      scale: shape.transform.scale).affineTransform
    selectionIndicatorView.isHidden = false

    selectionIndicatorViewShapeLayer.frame = selectionIndicatorView.bounds
    selectionIndicatorViewShapeLayer.path = UIBezierPath(rect: selectionIndicatorView.bounds).cgPath
  }

  private func redrawAbsolutelyEverything() {
    persistentBuffer = DrawsanaUtilities.renderImage(size: drawing.size) {
      for shape in self.drawing.shapes {
        shape.render(in: $0)
      }
    }
    reapplyLayerContents()
  }
}

// MARK: DrawsanaViewShapeUpdating implementation

extension DrawsanaView: DrawsanaViewShapeUpdating {
  /// Rerender all shapes from scratch. Very expensive for drawings with many shapes.
  public func rerenderAllShapesInefficiently() {
    redrawAbsolutelyEverything()
    applySelectionViewState()
  }
}

// MARK: Delegate implementations

extension DrawsanaView: DrawingDelegate {
  func drawingDidAddShape(_ shape: Shape) {
    persistentBuffer = DrawsanaUtilities.renderImage(size: drawing.size) {
      self.persistentBuffer?.draw(at: .zero)
      shape.render(in: $0)
    }
    reapplyLayerContents()
  }

  func drawingDidUpdateShape(_ shape: Shape) {
    redrawAbsolutelyEverything()
    applyToolSettingsChanges()
  }

  func drawingDidRemoveShape(_ shape: Shape) {
    redrawAbsolutelyEverything()
    if shape === toolSettings.selectedShape {
      toolSettings.selectedShape = nil
      applySelectionViewState()
    }
  }
}

extension DrawsanaView: ToolSettingsDelegate {
  func toolSettings(
    _ toolSettings: ToolSettings,
    didSetSelectedShape selectedShape: ShapeSelectable?)
  {
    applySelectionViewState()
    // DrawingView's delegate might set this, so notify the tool if it happens
    tool?.apply(context: toolOperationContext, userSettings: userSettings)
  }

  func toolSettings(
    _ toolSettings: ToolSettings,
    didSetInteractiveView interactiveView: UIView?,
    oldValue: UIView?)
  {
    guard oldValue !== interactiveView else { return }
    oldValue?.removeFromSuperview()
    if let interactiveView = interactiveView {
      interactiveOverlayContainerView.addSubview(interactiveView)
    }
  }

  func toolSettings(
    _ toolSettings: ToolSettings,
    didSetIsPersistentBufferDirty isPersistentBufferDirty: Bool)
  {
    // no-op; handled during tool operation
  }
}

extension DrawsanaView: UserSettingsDelegate {
  func userSettings(_ userSettings: UserSettings, didChangeStrokeColor strokeColor: UIColor?) {
    tool?.apply(context: toolOperationContext, userSettings: userSettings)
    applyToolSettingsChanges()
    delegate?.drawsanaView(self, didChangeStrokeColor: strokeColor)
  }

  func userSettings(_ userSettings: UserSettings, didChangeFillColor fillColor: UIColor?) {
    tool?.apply(context: toolOperationContext, userSettings: userSettings)
    applyToolSettingsChanges()
    delegate?.drawsanaView(self, didChangeFillColor: fillColor)
  }

  func userSettings(_ userSettings: UserSettings, didChangeStrokeWidth strokeWidth: CGFloat) {
    tool?.apply(context: toolOperationContext, userSettings: userSettings)
    applyToolSettingsChanges()
    delegate?.drawsanaView(self, didChangeStrokeWidth: strokeWidth)
  }

  func userSettings(_ userSettings: UserSettings, didChangeFontName fontName: String) {
    tool?.apply(context: toolOperationContext, userSettings: userSettings)
    applyToolSettingsChanges()
    delegate?.drawsanaView(self, didChangeFontName: fontName)
  }

  func userSettings(_ userSettings: UserSettings, didChangeFontSize fontSize: CGFloat) {
    tool?.apply(context: toolOperationContext, userSettings: userSettings)
    applyToolSettingsChanges()
    delegate?.drawsanaView(self, didChangeFontSize: fontSize)
  }
}

/**
 Small protocol wrapper around `DrawsanaView` that exposes just the
 `DrawingView.rerenderAllShapesInefficiently()` method, so tools can notify the
 drawing view that a shape has changed outside of a tool operation.

 See `DrawingTool.activate(shapeUpdater:context:shape:)`
 */
public protocol DrawsanaViewShapeUpdating: AnyObject {
  func rerenderAllShapesInefficiently()
}
