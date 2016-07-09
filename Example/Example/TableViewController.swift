//
//  TableViewController.swift
//  Example
//
//  Created by Nora Trapp on 3/21/15.
//
//

import UIKit
import Grapher

class TableViewController: UITableViewController {
    let numberOfPoints: Int = 50
    let maximumValue: CGFloat = 50
    let minimumValue: CGFloat = 0

    var pointData: [CGFloat] = []
    var tableData: [SectionData] = []

    override func viewDidLoad() {
        pointData = generateData()

        title = NSLocalizedString("Examples", comment: "")

        let lineGraphs: [CellData] = [CellData(type: .BezierCurveLine, title: NSLocalizedString("Bezier Curve", comment: "")),
                                    CellData(type: .StandardLine, title: NSLocalizedString("Standard", comment: ""))]

        tableData = [SectionData(title: NSLocalizedString("Standard Line Graphs", comment: ""), cellData: lineGraphs, style: .Standard),
            SectionData(title: NSLocalizedString("Dotted Line Graphs", comment: ""), cellData: lineGraphs, style: .Dotted),
            SectionData(title: NSLocalizedString("Dashed Line Graphs", comment: ""), cellData: lineGraphs, style: .Dashed)]


        tableView.registerClass(UITableViewCell.self, forCellReuseIdentifier: "default")
    }

    private func generateData() -> [CGFloat] {
        var data: [CGFloat] = []

        var previous: CGFloat?
        for i in 1...numberOfPoints {
            var d: CGFloat!
            let delta: CGFloat = CGFloat(maximumValue - minimumValue) * 0.1
            if let previous = previous {
                let random = CGFloat(1 + arc4random_uniform(UInt32(delta)))

                if previous >= CGFloat(maximumValue) - delta {
                    d = previous - random
                } else if previous <= CGFloat(minimumValue) + delta {
                    d = previous + random
                } else {
                    if arc4random_uniform(2) > 0 {
                        d = previous - random
                    } else {
                        d = previous + random
                    }
                }
            } else {
                d = CGFloat(arc4random_uniform(UInt32(maximumValue)))
            }
            data.append(d)
            previous = d
        }

        return data
    }

    // MARK: - Table View

    override func numberOfSectionsInTableView(tableView: UITableView) -> Int {
        return tableData.count
    }

    override func tableView(tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return tableData[section].count
    }

    override func tableView(tableView: UITableView, cellForRowAtIndexPath indexPath: NSIndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCellWithIdentifier("default") as! UITableViewCell

        let data = cellData(indexPath)

        cell.textLabel!.text = data.title

        return cell
    }

    override func tableView(tableView: UITableView, titleForHeaderInSection section: Int) -> String? {
        return tableData[section].title
    }

    override func tableView(tableView: UITableView, didSelectRowAtIndexPath indexPath: NSIndexPath) {
        tableView.deselectRowAtIndexPath(indexPath, animated: true)

        let sectionData = tableData[indexPath.section]
        let data = cellData(indexPath)

        let graphVC = GraphViewController(type: data.type, max: maximumValue, min: minimumValue, data: pointData, style: sectionData.style)
        navigationController?.pushViewController(graphVC, animated: true)
    }

    func cellData(indexPath: NSIndexPath) -> CellData {
        let sectionData = tableData[indexPath.section]
        return sectionData.cellData[indexPath.row]
    }
}

class CellData {
    let type: GraphType
    let title: String

    init(type ty: GraphType, title t: String) {
        title = t
        type = ty
    }
}

class SectionData {
    let title: String
    let cellData: [CellData]
    let style: GraphStyle
    var count: Int {
        get {
            return cellData.count
        }
    }

    init(title t: String, cellData c: [CellData], style s: GraphStyle) {
        title = t
        cellData = c
        style = s
    }
}
