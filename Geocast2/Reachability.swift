//
//  Reachability.swift
//  Geocast2
//
//  Created by Andrew Brown on 12/23/15.
//  Copyright © 2015 Andrew Brown. All rights reserved.
//

import Foundation
import UIKit
import SystemConfiguration

public class Reachability {
    class func isConnectedToNetwork() -> Bool {
        var zeroAddress = sockaddr_in()
        zeroAddress.sin_len = UInt8(sizeofValue(zeroAddress))
        zeroAddress.sin_family = sa_family_t(AF_INET)
        let defaultRouteReachability = withUnsafePointer(&zeroAddress) {
            SCNetworkReachabilityCreateWithAddress(nil, UnsafePointer($0))
        }
        var flags = SCNetworkReachabilityFlags()
        if !SCNetworkReachabilityGetFlags(defaultRouteReachability!, &flags) {
            return false
        }
        let isReachable = (flags.rawValue & UInt32(kSCNetworkFlagsReachable)) != 0
        let needsConnection = (flags.rawValue & UInt32(kSCNetworkFlagsConnectionRequired)) != 0
        return (isReachable && !needsConnection)
    }
    
    class func makeNoConnectionAlert() -> UIAlertController {
        let alertController = UIAlertController(title: "No Connection", message: "Please try again when you have a network connection.", preferredStyle: .Alert)
        let confirmAction = UIAlertAction(title: "Okay", style: .Default, handler: {
            (alert) in
        })
        alertController.addAction(confirmAction)
        return alertController
    }
}