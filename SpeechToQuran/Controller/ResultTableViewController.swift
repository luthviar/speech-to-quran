//
//  ResultTableViewController.swift
//  SpeechToQuran
//
//  Created by Luthfi Abdurrahim on 27/07/21.
//

import UIKit

class ResultTableViewController: UITableViewController {

    var resultArray: [AyatSearchResult]!    
    
    override func viewDidLoad() {
        super.viewDidLoad()
    }

    // MARK: - Table view data source

    override func numberOfSections(in tableView: UITableView) -> Int {
        return 1
    }

    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {        
        return resultArray.count
    }

    
    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "cellId", for: indexPath)

        cell.textLabel?.text = resultArray[indexPath.row].text
        let suratName = resultArray[indexPath.row].suratName
        let ayatId = resultArray[indexPath.row].ayatId
        let suratId = resultArray[indexPath.row].suratId
        cell.detailTextLabel?.text = "\(suratName) - \(suratId):\(ayatId)"        
        cell.accessoryType = .disclosureIndicator

        return cell
    }
    
    override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        let ayatId = resultArray[indexPath.row].ayatId
        let suratId = resultArray[indexPath.row].suratId
        if let url = URL(string: AppClient.getUrlAyat(suratId: suratId, ayatId: ayatId)) {
            UIApplication.shared.open(url)
        }
    }

}
