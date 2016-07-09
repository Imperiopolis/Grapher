//
//  GraphViewController.swift
//  
//
//  Created by Nora Trapp on 3/15/15.
//
//

import UIKit
import Grapher

enum GraphType: Equatable, Printable {
    case BezierCurveLine
    case StandardLine

    var description: String {
        get {
            switch self {
            case .BezierCurveLine:
                return "Bezier Curve"
            case .StandardLine:
                return "Standard Line"
            }
        }
    }
}

class GraphViewController: UIViewController {

    var graphView: GraphView!

    var graphData: [CGFloat]!
    var minimumValue: CGFloat!
    var maximumValue: CGFloat!
    var graphType: GraphType!
    var graphStyle: GraphStyle!

    convenience init(type: GraphType, max: CGFloat, min: CGFloat, data: [CGFloat], style: GraphStyle) {
        self.init()

        graphData = data
        minimumValue = min
        maximumValue = max
        graphType = type
        graphStyle = style
    }

    override func loadView() {
        switch graphType! {
        case .BezierCurveLine:
            fallthrough
        case .StandardLine:
            graphView = GraphView()
        }

        view = graphView
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()

        edgesForExtendedLayout = .None

        view.backgroundColor = UIColor.whiteColor()

        graphView.dataSource = self
        graphView.lineColor = UIColor.blackColor()
        graphView.lineWidth = 2
        graphView.minimumValue = minimumValue!
        graphView.maximumValue = maximumValue!
        graphView.lineStyle = graphStyle

        switch graphType! {
        case .BezierCurveLine:
            graphView.lineSmoothingStyle = .BezierCurve
        case .StandardLine:
            graphView.lineSmoothingStyle = .None
        }

        title = graphType.description + ": " + graphStyle.description

        graphView.reloadData(animated: true)
    }

    override func willTransitionToTraitCollection(newCollection: UITraitCollection, withTransitionCoordinator coordinator: UIViewControllerTransitionCoordinator) {
        coordinator.animateAlongsideTransition({ vc in
            self.graphView.reloadData(animated: false)

        }, completion: nil)
    }

    override func didRotateFromInterfaceOrientation(fromInterfaceOrientation: UIInterfaceOrientation) {
    }
}

extension GraphViewController: Graphable {
    func numberOfPointsInGraphView(graphView: GraphView) -> Int {
        return graphData.count
    }

    func graphView(graphView: GraphView, valueForPosition: Int) -> CGFloat? {
        return graphData[valueForPosition]
    }
}
