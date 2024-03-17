//
//  ConversationModels.swift
//  MessangerApp
//
//  Created by beyza nur on 17.03.2024.
//

import Foundation

struct Conversation{
    let id : String
    let name :String
    let otherUserEmail:String
    let latestMessage :LatestMessage
}

struct LatestMessage {
    let date:String
    let text :String
    let isRead : Bool
}
