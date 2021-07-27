//
//  AppClient.swift
//  SpeechToQuran
//
//  Created by Luthfi Abdurrahim on 27/07/21.
//

import Foundation
import Alamofire
import SystemConfiguration

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
                if resultArray.count > 0 {
                    let sortedArray = resultArray.sorted { (lhs, rhs) in return lhs.index < rhs.index }
                    resultArray = sortedArray
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
        
    
}

class Connectivity {
    static var isConnectedToInternet: Bool {
        //return NetworkReachabilityManager()!.isReachable
        return isConnectedToNetwork()
    }
    
    enum Status {
        case notConnected, connected, other
    }
        
    class func isConnectedToNetwork() -> Bool {

        var zeroAddress = sockaddr_in(sin_len: 0, sin_family: 0, sin_port: 0, sin_addr: in_addr(s_addr: 0), sin_zero: (0, 0, 0, 0, 0, 0, 0, 0))
        zeroAddress.sin_len = UInt8(MemoryLayout.size(ofValue: zeroAddress))
        zeroAddress.sin_family = sa_family_t(AF_INET)

        let defaultRouteReachability = withUnsafePointer(to: &zeroAddress) {
           $0.withMemoryRebound(to: sockaddr.self, capacity: 1) {zeroSockAddress in
               SCNetworkReachabilityCreateWithAddress(nil, zeroSockAddress)
           }
        }

        var flags: SCNetworkReachabilityFlags = SCNetworkReachabilityFlags(rawValue: 0)
        if SCNetworkReachabilityGetFlags(defaultRouteReachability!, &flags) == false {
           return false
        }

        /* Only Working for WIFI
        let isReachable = flags == .reachable
        let needsConnection = flags == .connectionRequired

        return isReachable && !needsConnection
        */

        // Working for Cellular and WIFI
        let isReachable = (flags.rawValue & UInt32(kSCNetworkFlagsReachable)) != 0
        let needsConnection = (flags.rawValue & UInt32(kSCNetworkFlagsConnectionRequired)) != 0
        let ret = (isReachable && !needsConnection)

        return ret
    }
}
