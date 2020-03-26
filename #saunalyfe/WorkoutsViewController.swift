//
//  WorkoutsViewController.swift
//  #saunalyfe
//
//  Created by Dan Hogan on 3/25/20.
//  Copyright © 2020 Dan Hogan. All rights reserved.
//

import UIKit
import HealthKit

private let kCellId = "CellId"

class WorkoutsViewController: UIViewController, UITableViewDataSource, UITableViewDelegate {

    let healthStore = HKHealthStore()
    
    let tableView = UITableView()
    let workouts: [ HKWorkout ]
    var heartRateDict = [ Int : Int ]()

    init(workouts theWorkouts: [ HKWorkout]) {
        workouts = theWorkouts
        super.init(nibName: nil, bundle: nil)
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        view.addGradientLayer()

        view.addSubview({
            tableView.contentInset.top = 40.0
            tableView.dataSource = self
            tableView.delegate = self
            tableView.frame = view.frame
            tableView.backgroundColor = UIColor.clear
            tableView.separatorColor = UIColor.white
            tableView.tableFooterView = UIView()
            
            return tableView
            }()
        )
    }
    
    //MARK:- Layout
    
    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        
        tableView.contentInset.bottom = view.safeAreaInsets.bottom + 20.0
    }
    
    //MARK:- Tableview

    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return workouts.count
    }

    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell: UITableViewCell
        if let _cell = tableView.dequeueReusableCell(withIdentifier: kCellId) {
            cell = _cell
        } else {
            cell = UITableViewCell(style: .subtitle, reuseIdentifier: kCellId)
        }
        
        let row = indexPath.row
        cell.selectionStyle = .none
        cell.backgroundColor = UIColor.clear
        let workout = workouts[row]
        cell.textLabel?.textColor = UIColor.white
        cell.textLabel?.font = UIFont.systemFont(ofSize: 24.0, weight: .medium)
        cell.detailTextLabel?.textColor = UIColor.white
        cell.detailTextLabel?.font = UIFont.systemFont(ofSize: 21.0, weight: .thin)
        let start = workout.startDate.timeIntervalSince1970
        let end = workout.endDate.timeIntervalSince1970
        let duration = end - start
        cell.textLabel?.text = duration.formattedTime
        cell.detailTextLabel?.text = start.monthDayTime + " - " + end.timeOnly

        if let bpm = heartRateDict[row] {
            cell.textLabel!.text! += ", \(bpm) bpm"
        } else {
            let predicate: NSPredicate? = HKQuery.predicateForSamples(
                withStart: workout.startDate,
                end: workout.endDate,
                options: HKQueryOptions.strictEndDate
            )

            let query = HKStatisticsQuery(
                quantityType: kHeartRateQuantityType,
                quantitySamplePredicate: predicate,
                options: .discreteAverage) { query, statistics, error in
                    if let quantity = statistics?.averageQuantity()?.doubleValue(for: kHeartRateUnit) {
                        let heartRate = Int(round(quantity))
                        self.heartRateDict[row] = heartRate
                        DispatchQueue.main.async {
                            tableView.reloadRows(at: [ indexPath ], with: .automatic)
                        }
                    }

            }
            
            healthStore.execute(query)
        }
        
        return cell
    }
        
    func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        return UITableView.automaticDimension
    }
}