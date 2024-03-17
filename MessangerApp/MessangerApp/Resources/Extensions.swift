//
//  Extensions.swift
//  MessangerApp
//
//  Created by beyza nur on 14.02.2024.
//

import Foundation
import UIKit

//kullanıcagımız uıkit extensions ları burda yaratıcaz
extension UIView{
    
    public var width:CGFloat{
        return frame.size.width
    }
    
    public var height:CGFloat{
        return frame.size.height
    }
    
    public var top:CGFloat{
        return frame.origin.y
    }
    
    public var bottom:CGFloat{
        return frame.size.height + frame.origin.y
    }
    
    public var left:CGFloat{
        return frame.origin.x
    }
    
    public var right:CGFloat{
        return frame.size.width + frame.origin.x
    }
    
}

extension Notification.Name{
    ///notification when user logs in
    static let didLogInNotification=Notification.Name("didLogInNotification")
}
