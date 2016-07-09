//
//  GraphView.swift
//  Grapher
//
//  Created by Nora Trapp on 3/15/15.
//  Copyright (c) 2015 Trapp Design. All rights reserved.
//

import UIKit

/**
Types representing the different graph styles.

- Standard: Simple line between points
- Dashed:   Dashed line between points.
- Dotted:   Dotted line between points.
*/
public enum GraphStyle: Equatable, Printable {
    case Standard
    case Dashed
    case Dotted
    
    public var description: String {
        get {
            switch self {
            case .Standard:
                return "Standard"
            case .Dashed:
                return "Dashed"
            case .Dotted:
                return "Dotted"
            }
        }
    }
}

/**
Defines the smoothing style of the graph.

- None:            No smoothing is applied.
- BezierCurve:     Smooth graph using a bezier curve between points.
*/
public enum GraphSmoothingStyle: Equatable, Printable {
    case None
    case BezierCurve

    public var description: String {
        get {
            switch self {
            case .None:
                return "None"
            case .BezierCurve:
                return "Bezier Curve"
            }
        }
    }
}

/**
*  An instance of GraphView (or simply, a graph view) is a means for displaying evenly spaced linear information within a graph. General usage includes graphs over fixed periods, such as time or distance, with a regularly spaced data source.
*/
public class GraphView: UIView {

    /// The style of line used by the view, defaults to Standard
    public var lineStyle: GraphStyle = .Standard {
        didSet {
            if oldValue != lineStyle {
                hasAppliedStyle = false
                styleLayer()
            }
        }
    }
    /// The style of line smoothing to use. Defaults to no smoothing.
    public var lineSmoothingStyle: GraphSmoothingStyle = .None {
        didSet {
            if oldValue != lineSmoothingStyle {
                hasAppliedStyle = false
                styleLayer()
            }
        }
    }

    /// The width of the rendered line
    public var lineWidth: CGFloat? {
        didSet {
            if oldValue != lineWidth {
                hasAppliedStyle = false
                styleLayer()
            }
        }
    }
    /// The color of the rendered line
    public var lineColor: UIColor? {
        didSet {
            if oldValue != lineColor {
                hasAppliedStyle = false
                styleLayer()
            }
        }
    }

    /// The minimum X value within the graph
    public var minimumValue = CGFloat.min
    /// The maximum X value within the graph
    public var maximumValue = CGFloat.max
    
    public weak var dataSource: Graphable?
    
    // Data
    
    private var points: [GraphPoint] = []
    private var hasAppliedStyle = false

    /**
    Reloads and renders all point data.

    :param: animated Animate rendering of graph data.
    */
    public func reloadData(#animated: Bool) {
        buildPointsData() { [unowned self] path in
            self.drawPoints(animated: animated, path: path)
        }
    }
    
    // Info

    /**
    The total number of points to be rendered.

    :returns: Number of points.
    */
    public func numberOfPoints() -> Int {
        if let dataSource = dataSource {
            return dataSource.numberOfPointsInGraphView(self)
        }
        
        return 0
    }

    /**
    The x value to graph at a specific position.

    :param: position The y position for which to return an appropriate x value.

    :returns: The x value for the given position.
    */
    public func valueForPosition(position: Int) -> CGFloat? {
        if let dataSource = dataSource {
            return dataSource.graphView(self, valueForPosition: position)
        }
        
        return nil
    }

    /**
    Generates the x, y pairing for a given position.

    :param: position The position along the y axis.

    :returns: The x, y pairing for a given position
    */
    public func pointForPosition(position: Int) -> CGPoint? {
        if let value = valueForPosition(position) {
            return CGPointMake(CGFloat(position), value)
        }
        
        return nil
    }

    // MARK: - Overrides
    public override func didMoveToWindow() {
        styleLayer()
    }

    // Setup layer as a CAShapeLayer, to handle our bezier path
    override public class func layerClass() -> AnyClass {
        return CAShapeLayer.self
    }
    
    var shapeLayer: CAShapeLayer {
        get {
            return layer as! CAShapeLayer
        }
    }
}

/**
*  A graphable data source.
*/
public protocol Graphable: class {
    /**
    The total number of points to be rendered.

    :param: graphView The requesting graph view, where the points will be rendered.

    :returns: The number of points to be rendered.
    */
    func numberOfPointsInGraphView(graphView: GraphView) -> Int

    /**
    The x value to graph at a specific position y.

    :param: graphView        The requesting graph view, where the points will be rendered.
    :param: valueForPosition The y position.

    :returns: The x value for the given position y.
    */
    func graphView(graphView: GraphView, valueForPosition: Int) -> CGFloat?
}

// MARK: - Internal
private func ==(lhs: GraphPoint, rhs: GraphPoint) -> Bool {
    return lhs.point == rhs.point && lhs.rawPoint == rhs.rawPoint
}

private class GraphPoint: Printable, Equatable {
    init(point p: CGPoint, rawPoint r: CGPoint) {
        point = p
        rawPoint = r
    }
    
    var point: CGPoint
    var rawPoint: CGPoint
    
    var y: CGFloat {
        get {
            return point.y
        }
        set {
            point.y = newValue
        }
    }
    
    var x: CGFloat {
        get {
            return point.x
        }
        set {
            point.x = newValue
        }
    }
    
    var description: String {
        get {
            return NSStringFromCGPoint(rawPoint)
        }
    }
}

private extension GraphView {
    
    // Calculate normalized point data on a background queue
    func buildPointsData(completion: (path: UIBezierPath) -> Void) {
        dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0)) { [unowned self] in

            let date = NSDate()

            var points: [GraphPoint] = []
            var path = UIBezierPath()
            var previousPoint: CGPoint?
            
            for x in 0...(self.numberOfPoints() - 1) {
                // Ideally, these could be one if-let statement
                let (point, rawPoint) = self.normalizedPoint(x: CGFloat(x), y: self.valueForPosition(x))
                if let point = point, rawPoint = rawPoint {
                    points.append(GraphPoint(point: point, rawPoint: rawPoint))

                    if let previousPoint = previousPoint {
                        if self.lineSmoothingStyle == .BezierCurve {
                            let deltaX = point.x - previousPoint.x;
                            let controlPointX = previousPoint.x + (deltaX / 2);

                            let controlPoint1 = CGPointMake(controlPointX, previousPoint.y);
                            let controlPoint2 = CGPointMake(controlPointX, point.y);

                            path.addCurveToPoint(point, controlPoint1: controlPoint1, controlPoint2: controlPoint2)
                        } else {
                            path.addLineToPoint(point)
                        }
                    } else {
                        path.moveToPoint(point)
                    }
                    
                    previousPoint = point
                }
            }
            
            self.points = points

            completion(path: path)
        }
    }
    
    // Drawing

    func drawPoints(#animated: Bool, path: UIBezierPath) {
        assert(lineColor != nil, "Cannot draw points without a defined line color")
        assert(lineWidth != nil, "Cannot draw points without a defined line width")

        let date = NSDate()

        shapeLayer.path = nil
        shapeLayer.removeAllAnimations()

        styleLayer()

        shapeLayer.path = path.CGPath

        shapeLayer.needsDisplay()

        if animated {
            animatePath()
        }
    }
    
    func styleLayer() {
        if !hasAppliedStyle && window != nil {
            hasAppliedStyle = true

            if let lineWidth = lineWidth, lineColor = lineColor {
                shapeLayer.lineWidth = lineWidth
                shapeLayer.strokeColor = lineColor.CGColor
            }

            shapeLayer.fillColor = UIColor.clearColor().CGColor

            if lineSmoothingStyle == .BezierCurve {
                shapeLayer.lineCap = kCALineCapRound
                shapeLayer.lineJoin = kCALineJoinRound
            } else {
                shapeLayer.lineCap = kCALineCapButt
                shapeLayer.lineJoin = kCALineJoinMiter
            }

            switch lineStyle {
            case .Dashed:
                shapeLayer.lineDashPattern = [4, 4]
            case .Dotted:
                shapeLayer.lineDashPattern = [2, 6]
                shapeLayer.lineCap = kCALineCapRound
                shapeLayer.lineJoin = kCALineJoinRound
            case .Standard:
                break
            }
        }
    }
    
    func animatePath() -> CABasicAnimation {
        let drawPath = CABasicAnimation(keyPath: "strokeEnd")
        drawPath.delegate = self;
        drawPath.fromValue = 0;
        drawPath.toValue = 1;
        drawPath.duration = 1;
        drawPath.fillMode = kCAFillModeForwards;
        drawPath.removedOnCompletion = true;
        layer.addAnimation(drawPath, forKey: nil)
        
        return drawPath;
    }
    
    // Normalizing
    
    func normalizedPoint(#x: CGFloat?, y: CGFloat?) -> (CGPoint?, CGPoint?) {
        if let rawX = x, rawY = y {
            let rawPoint = CGPointMake(rawX, rawY)
            var point: CGPoint?
            
            if maximumValue - minimumValue <= 0 {
                point = nil
            } else {
                let y = CGRectGetHeight(bounds) - ((rawY - minimumValue) / (maximumValue - minimumValue)) * CGRectGetHeight(bounds)
                let x = rawX * (CGRectGetWidth(bounds) / CGFloat(numberOfPoints()))
                
                point = CGPointMake(x, y)
            }
            
            return (point, rawPoint)
        }
        
        return (nil, nil)
    }
}
