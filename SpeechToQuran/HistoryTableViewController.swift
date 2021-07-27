//
//  HistoryTableViewController.swift
//  SpeechToQuran
//
//  Created by Luthfi Abdurrahim on 27/07/21.
//

import UIKit
import CoreData

class HistoryTableViewController: UITableViewController {

    // MARK: Properties
    var searchResultAttempts: [SearchResultAttempt]!
    var fetchedResultsController: NSFetchedResultsController<Attempt>!
    
    override func viewDidLoad() {
        super.viewDidLoad()
    }

    // MARK: - Table view data source

    override func numberOfSections(in tableView: UITableView) -> Int {
        return 1
    }

    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {        
        return searchResultAttempts.count
    }

    
    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "historyCellId", for: indexPath)

        cell.textLabel?.text = searchResultAttempts[indexPath.row].speechText
        cell.detailTextLabel?.text = searchResultAttempts[indexPath.row].timestamp.description
        cell.accessoryType = .disclosureIndicator

        return cell
    }
    
    override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {        
        let attempt = fetchedResultsController.object(at: indexPath)
        var ayatSearchResults: [AyatSearchResult] = []
        if let results = attempt.results {
            for item in results {
                let theResult: Result = item as! Result
                let newAyatSearchResult = AyatSearchResult(index: Int(theResult.index), text: theResult.text!, suratName: theResult.suratName!, suratId: Int(theResult.suratId), ayatId: Int(theResult.ayatId), ayatIdGlobal: Int(theResult.ayatIdGlobal))
                ayatSearchResults.append(newAyatSearchResult)
            }
        }
        let sortedArray = ayatSearchResults.sorted { (lhs, rhs) in return lhs.index < rhs.index }
        presentResultView(resultArray: sortedArray)
    }
    
    // MARK: Present
    func presentResultView(resultArray: [AyatSearchResult]) {
        let resultTableVC = self.storyboard!.instantiateViewController(withIdentifier: "ResultTableViewController") as! ResultTableViewController
        resultTableVC.resultArray = resultArray
        present(resultTableVC, animated: true, completion: nil)
    }

}
