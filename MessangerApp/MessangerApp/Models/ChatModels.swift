//
//  ChatModels.swift
//  MessangerApp
//
//  Created by beyza nur on 17.03.2024.
//

import Foundation
import CoreLocation
import MessageKit
import UIKit
//message Type messagekit sayesinde geliyor
struct Message: MessageType {
    
    public var sender: SenderType
    public var messageId: String
    public var sentDate: Date
    public var kind:MessageKind
     //messagekind text olabilir,video,photo,location,emoji,audiomessage,contact,link
}
extension MessageKind {
    var messageKindString:String{
        switch self{
        case .text(_):
            return "text"
        case .attributedText(_):
            return "attributed_text"
        case .photo(_):
            return "photo"
        case .video(_):
            return "video"
        case .location(_):
            return "location"
        case .emoji(_):
            return "emoji"
        case .audio(_):
            return "audio"
        case .contact(_):
            return "contact"
        case .linkPreview(_):
            return "link_preview"
        case .custom(_):
            return "custom"
        }
    }
}
struct Sender: SenderType {
    
   public var photoURL:String
   public var senderId: String
   public var displayName: String
    
}
struct Media : MediaItem{
    var url: URL?
    var image: UIImage?
    var placeholderImage: UIImage
    var size: CGSize
    
    
}

struct Location : LocationItem{
    var location: CLLocation
    var size: CGSize
}
