//
//  AppClient.swift
//  SpeechToQuran
//
//  Created by Luthfi Abdurrahim on 27/07/21.
//

import Foundation
import Alamofire

class AppClient {
    struct Constants {
        static let BASE_URL_API_SEARCH = "http://alfanous.org/api/search"
        static let PARAM_QUERY_SEARCH = "?query="
        static let BASE_URL_QURAN = "https://quran.com"
    }
    
    static func getSearchResult(query: String, completionHandler: @escaping (Connectivity.Status, [AyatSearchResult]?, Error?) -> Void ) {
        let stringUrl = "\(Constants.BASE_URL_API_SEARCH)\(Constants.PARAM_QUERY_SEARCH)\(query)"
        let url = stringUrl.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed)!
        
        if !Connectivity.isConnectedToInternet {
            completionHandler(.notConnected, [], nil)
        }
        
        AF.request(url).responseJSON { (response) in
            var resultArray: [AyatSearchResult] = []
            if let jsonResponse = try! JSONSerialization.jsonObject(with: response.data!, options: .allowFragments) as? [String: Any] {
                let search = jsonResponse["search"] as! [String:Any]
                let ayats = search["ayas"] as! [String:[String:Any]]
                for item in ayats {
                    let object = item.value
                    let ayat = object["aya"] as! [String:Any]
                    let identifier = object["identifier"] as! [String:Any]
                    let ayatText: String = ayat["text_no_highlight"] as! String
                    let suratName: String = identifier["sura_name"] as! String
                    let suratId: Int = identifier["sura_id"] as! Int
                    let ayatId: Int = identifier["aya_id"] as! Int
                    let ayatIdGlobal: Int = identifier["gid"] as! Int
                    let indexResult: Int = Int(item.key)!
                    let result = AyatSearchResult(index: indexResult, text: ayatText, suratName: suratName, suratId: suratId, ayatId: ayatId, ayatIdGlobal: ayatIdGlobal)
                    resultArray.append(result)
                }
                completionHandler(.connected, resultArray, nil)
            } else {
                completionHandler(.connected, [], nil)
            }
        }
    }
    
    static func getUrlAyat(suratId: Int, ayatId: Int) -> String {
        let urlAyat = "\(Constants.BASE_URL_QURAN)/\(suratId)/\(ayatId)"
        return urlAyat
    }
    
//    AF.request(url).responseJSON { (response) in
//        let jsonResponse = try! JSONSerialization.jsonObject(with: response.data!, options: .allowFragments) as? [String: Any]
//        let photos = jsonResponse!["photos"] as! [String: Any]
//        let totalPages = photos["pages"] as! Int
//        let photosPerPages = photos["photo"] as! [[String:Any]]
//        var photosURL: [String] = []
//
//        for photo in photosPerPages {
//            let farm: Int = photo["farm"] as! Int
//            let server = photo["server"]!
//            let id = photo["id"]!
//            let secret: String = photo["secret"] as! String
//            let photoURL = "https://farm\(farm).staticflickr.com/\(server)/\(id)_\(secret).jpg"
//            photosURL.append(photoURL)
//        }
//
//        completionHandler(.connected, photosURL, totalPages)
//
//    }
}

class Connectivity {
    static var isConnectedToInternet: Bool {
        return NetworkReachabilityManager()!.isReachable
    }
    
    enum Status {
        case notConnected, connected, other
    }
}
