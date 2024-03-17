//
//  DatabaseManager.swift
//  MessangerApp
//
//  Created by beyza nur on 14.02.2024.
//

import Foundation
import FirebaseDatabase
import MessageKit
import UIKit
import CoreLocation

final class DatabaseManager {
    //shared singleton yani her yerden erişilebilir nesne olusturuyoruz ve conversationVC de kullanıcaz bunu
    static let shared=DatabaseManager()
    
    //private kuruyorum ki kimse erişemesin
    private let database=Database.database().reference()
    
    
    static func safeEmail(emailAdress:String) -> String{
        var safeEmail=emailAdress.replacingOccurrences(of: ".", with: "-")
        safeEmail=safeEmail.replacingOccurrences(of: "@", with: "-")
        return safeEmail
    }
}
extension DatabaseManager{
    ///returns dictionary node at child path
    public func getDataFor(path : String , completion : @escaping (Result<Any,Error>) ->Void){
        database.child("\(path)").observeSingleEvent(of: .value) { snapshot in
            guard let value = snapshot.value else{
                completion(.failure(DatabaseError.failedToFetch))
                return
            }
            completion(.success(value))
        }
    }
}

//Account Management
extension DatabaseManager {
    //yeni kullanıcıların kullanılmış eposta almasını önlemek için
    //true dönerse o email kullanılamaz
    ///checks if user exists for given email
    ///parametreler email ve completion
    ///-completion :async closure to return with result
    public func userExists(with email : String, completion : @escaping ((Bool) -> Void)){
        
        //var safeEmail=email.replacingOccurrences(of: ".", with: "-")
        //safeEmail=safeEmail.replacingOccurrences(of: "@", with: "-")
        var safeEmail = DatabaseManager.safeEmail(emailAdress: email)
        
        database.child(safeEmail).observeSingleEvent(of: .value) { snapshot in
            guard snapshot.value as? [String:Any] != nil else{
                completion(false)
                return
            }
            completion(true)
        }
    }
    
    ///Insert new users to database
    public func insertUser(with user :ChatAppUser ,completion : @escaping (Bool) -> Void){
        database.child(user.safeEmail).setValue([
            "first_name" : user.firstName,
            "last_name" : user.lastName
            
            //kullanıcı email ini anahtar olarak kullanıp içinde her şeyini tutucaz
            // database içinde foo yazan veri oluşturdu ve içinde something diye bir şey tutuyı değeri true
            // database.child("foo").setValue(["something" : true])
        ]) {[weak self] error, _ in
            guard let strongSelf = self else{
                return
            }
            guard error == nil else {
                print("failed to write to database")
                completion(false)
                return
            }
            
            /* realtime database imiz bu şekilde ollsun istiyoruz
             // yeni bi sohbet baslatılacağında users ın içideki arrayın içindekiler gelsin ekrana
             users => [
             
             [
             "name":
             "safe_email":
             
             ],
             [
             "name":
             "safe_email":
             ]
             
             ]
             */
            
            //database imizde users koleksiyonu var mı ona bakıyoruz
            strongSelf.database.child("users").observeSingleEvent(of: .value) { snapshot in
                if var usersCollection = snapshot.value as? [[String:String]] {
                    //user koleksiyonu varsa ona yeni userı ekliyoruz
                    let newElement=["name":user.firstName + " " + user.lastName,
                                    "safe_email":user.safeEmail]
                    usersCollection.append(newElement)
                    
                    strongSelf.database.child("users").setValue(usersCollection) { error, dbReference in
                        guard error == nil else{
                            completion(false)
                            return
                        }
                        completion(true)
                    }
                    
                }else{
                    //create that array
                    let newCollection : [[String:String]] = [
                        ["name":user.firstName + " " + user.lastName,
                         "safe_email":user.safeEmail]
                    ]
                    strongSelf.database.child("users").setValue(newCollection) { error, dbReference in
                        guard error == nil else{
                            completion(false)
                            return
                        }
                        completion(true)
                    }
                    
                }
            }
            completion(true)
        }
        
    }
    
    
    public func getAllUsers(completion:@escaping (Result<[[String:String]],Error>) ->Void){
        database.child("users").observeSingleEvent(of: .value, with: { snapshot in
            guard let value = snapshot.value as? [[String:String]] else{
                completion(.failure(DatabaseError.failedToFetch))
                return
            }
            //kullanıcılarımızın oldugu dizi
            completion(.success(value))
            print("\(value.count) GET ALL USERS ÇALIŞIOR FİLTERED USERS RESULT I BOS GÖSTERİYOR")
           
            
        })
    }
    
    public enum DatabaseError : Error{
        case failedToFetch
        
        public var localizedDescription: String {
                   switch self {
                   case .failedToFetch:
                       return "Database fetching failed"
                   }
               }
        
    }
    
    
}


//MARK: -SENDING MESSAGES/CONVERSATIONS

/*
 "adfshfsv" {
 "messages": [ {
 "id":String,
 "type":text,
 "content":string,
 "date":Date(),
 "sender_email":string,
 "isRead":true/false
 }
 ]
 }
 
 conversation => [
 
 [
 "conversationId":"adfshfsv"
 "other_user_email":
 "latest_message": =>{
 "date": Date()
 "latest_message":"message"
 "is_read":true/false
 }
 
 
 ] ]
 */


extension DatabaseManager {
    
    ///creates new convo with target user and first message sent
    public func createNewConversation(with otherUserEmail: String ,name : String, firstMessage:Message,completion : @escaping (Bool) ->Void){
        guard let currentEmail = UserDefaults.standard.value(forKey: "email") as? String,
              let currentName = UserDefaults.standard.value(forKey: "name") as? String else{
            return
        }
        let safeEmil=DatabaseManager.safeEmail(emailAdress: currentEmail)
        //current usersnode reference
        let ref = database.child("\(safeEmil)")
        ref.observeSingleEvent(of: .value ) { [unowned self] snapshot in
            guard  var userNode = snapshot.value as? [String:Any] else {
                completion(false)
                print("user not found")
                return
            }
            
            let messageDate  = firstMessage.sentDate
            let dateString = ChatViewController.dateFormatter.string(from: messageDate)
            var message = " "
            switch firstMessage.kind {
                
            case .text(let messageText):
                message=messageText
            case .attributedText(_):
                break
            case .photo(let mediaItem):
                if let targetUrlString = mediaItem.url?.absoluteString {
                    message = targetUrlString
                }
                break
            case .video(_):
                break
            case .location(_):
                break
            case .emoji(_):
                break
            case .audio(_):
                break
            case .contact(_):
                break
            case .linkPreview(_):
                break
            case .custom(_):
                break
            }
            let conversationID="conversastion_\(firstMessage.messageId)"
            
            let newConversationData: [String:Any] = [
                "id": conversationID,
                "other_user_email":otherUserEmail,
                "name":name,
                "latest_message": [
                    "date": dateString ,
                    "message":message,
                    "is_read":false
                ]
            ]
            let recipient_newConversationData: [String:Any] = [
                "id": conversationID,
                "other_user_email":safeEmil,
                "name":currentName,
                "latest_message": [
                    "date": dateString ,
                    "message":message,
                    "is_read":false
                ]
            ]
            //update recipient convo entry
            self.database.child("\(otherUserEmail)/conversations").observeSingleEvent(of: .value) {  [weak self] snapshot in
                if var conversations = snapshot.value as? [[String:Any]] {
                    //append eger varsa
                    conversations.append(recipient_newConversationData)
                    self?.database.child("\(otherUserEmail)/conversations").setValue(conversations)
                }
                else{
                    //yoksa oluştur
                    self?.database.child("\(otherUserEmail)/conversations").setValue([recipient_newConversationData])
                }
            }
            
            //update current user conversation entry
            if var conversations = userNode["conversations"] as? [[String:Any]] {
                //conversation array varsa eğer,ekleme yapıcaz
                conversations.append(newConversationData)
                userNode["conversations"] = conversations
                ref.setValue(userNode) { [weak self] error, _ in
                    guard error == nil else{
                        completion(false)
                        return
                    }
                    //completion(true)
                    self?.finishCreatingConversation( name: name ,
                                                      conversationId: conversationID,
                                                      firstMessage: firstMessage,
                                                      completion: completion)
                }
            }else{
                print("calıstı")
                //conversation array yokmus,oluşturucaz
                userNode["conversations"] = [
                    newConversationData
                ]
                ref.setValue(userNode) { [weak self ]error, _ in
                    guard error == nil else{
                        completion(false)
                        return
                    }
                    self?.finishCreatingConversation( name: name ,
                                                      conversationId: conversationID,
                                                      firstMessage: firstMessage,
                                                      completion: completion
                    )
                }
            }
        }
    }
    
    private func finishCreatingConversation(name:String, conversationId:String,firstMessage:Message,completion:@escaping (Bool)->Void){
        //        {
        //           "id":String,
        //           "type":text,
        //           "content":string,
        //           "date":Date(),
        //           "sender_email":string,
        //           "isRead":true/false
        //        }
        //        ]
        //        }
        let messageDate  = firstMessage.sentDate
        //database de sadee string saklıyo
        let dateString = ChatViewController.dateFormatter.string(from: messageDate)
        
        var message = " "
        switch firstMessage.kind {
            
        case .text(let messageText):
            message=messageText
        case .attributedText(_):
            break
        case .photo(_):
            break
        case .video(_):
            break
        case .location(_):
            break
        case .emoji(_):
            break
        case .audio(_):
            break
        case .contact(_):
            break
        case .linkPreview(_):
            break
        case .custom(_):
            break
        }
        guard let myEmail = UserDefaults.standard.value(forKey: "email") as? String else{
            completion(false)
            return
        }
        let currentUserEmail = DatabaseManager.safeEmail(emailAdress: myEmail)
        
        let collectionMessage: [String:Any] = [
            "id":firstMessage.messageId,
            "type":firstMessage.kind.messageKindString,
            "content":message,
            "date":dateString,
            "sender_email":currentUserEmail,
            "is_Read":false,
            "name":name
        ]
        let value :[String:Any] = [
            "messages": [
                collectionMessage
            ]
        ]
        print("adding convo \(conversationId)")
        
        database.child("\(conversationId)").setValue(value) { error, _ in
            guard error == nil else{
                completion (false)
                return
            }
            completion(true)
        }
        
    }
    
    ///fetches and returns all convos for user with passed in email
    public func getAllConversations(for email:String,completion:@escaping (Result<[Conversation],Error>) ->Void){
        //listener olupşturduk, conversationdaki her value değiştiğinde handler ı çağrıck
        database.child("\(email)/conversations").observe(.value) { snapshot   in
            guard let value = snapshot.value as? [[String:Any]] else {
                completion(.failure(DatabaseError.failedToFetch))
                print("hata burda")
                print("Veri alınamadı. Snapshot: \(snapshot)")
                return
            }
            // alabildiysek convo array i oluşturucaz
            let conversations :[Conversation] = value.compactMap( { dictionary in
                guard let conversationId = dictionary["id"] as? String ,
                      let name = dictionary["name"] as? String,
                      let otherUserEmail = dictionary["other_user_email"] as? String,
                      let latestMessage = dictionary["latest_message"] as? [String:Any],
                      let date = latestMessage["date"] as? String,
                      let message = latestMessage["message"] as? String,
                      let isRead = latestMessage["is_read"] as? Bool else {
                    return nil
                }
                
                let latestMessageObject = LatestMessage(date: date,
                                                        text: message,
                                                        isRead: isRead)
                return Conversation(id: conversationId, name: name, otherUserEmail: otherUserEmail, latestMessage: latestMessageObject)
            })
            completion(.success(conversations))
        }
    }
    
    /// gets all messages for a given convo
    public func getAllMessagesForConversation(with id :String,completion:@escaping (Result<[Message],Error>) ->Void){
        //listener olupşturduk, conversationdaki her value değiştiğinde handler ı çağrıck
        database.child("\(id)/messages").observe(.value) { snapshot,ae  in
            guard let value = snapshot.value as? [[String:Any]] else {
                completion(.failure(DatabaseError.failedToFetch))
                print("Veri alınamadı. Snapshot: \(snapshot)")
                return
            }
            // alabildiysek convo array i oluşturucaz
            let messages :[Message] = value.compactMap( {dictionary in
                guard let name=dictionary["name"] as? String ,
                      let isRead = dictionary["is_Read"] as? Bool,
                      let messageId = dictionary["id"] as? String,
                      let content = dictionary["content"] as? String,
                      let dateString = dictionary["date"] as? String,
                      let type = dictionary["type"] as? String,
                      let senderEmail = dictionary["sender_email"] as? String,
                      let date = ChatViewController.dateFormatter.date(from: dateString) else {
                    return Message(sender: Sender(photoURL: "", senderId: "", displayName: ""), messageId: "", sentDate: Date(), kind: .text(""))
                }
                var kind : MessageKind?
                if type == "photo" {
                    //photo
                    guard let imageUlr=URL(string: content),
                          let placeHolder = UIImage(named: "video_placeholder") else{
                        return nil
                    }
                    let media = Media(url:imageUlr,image:nil,placeholderImage: placeHolder, size: CGSize(width: 300, height: 300))
                    kind = .photo(media)
                }else if type == "video"{
                    guard let videoUrl=URL(string: content),
                          let placeHolder = UIImage(named: "video_placeholder") else{
                        return nil
                    }
                    let media = Media(url:videoUrl,image:nil,placeholderImage: placeHolder, size: CGSize(width: 300, height: 300))
                    kind = .video(media)
                }
                else if type == "location" {
                    let locationComponents = content.components(separatedBy: ",")
                     guard let longitude = Double(locationComponents[0]),
                           let latitude = Double(locationComponents[1])  else{
                         return nil
                     }
                    print("rendering location : long=\(longitude), lat=\(latitude)")
                    let location = Location(location: CLLocation(latitude: latitude, longitude: longitude), size: CGSize(width: 300, height: 300))
                    kind = .location(location)
                    
                }
                else{
                    kind = .text(content)
                }
                guard let finalKind = kind else{
                    return nil
                }
                
                let sender = Sender(photoURL: " ", senderId: senderEmail, displayName: name)
                
                return Message(sender: sender, messageId: messageId, sentDate: date, kind: finalKind)
            })
            
            completion(.success(messages))
        }
    }
    
    ///sends a message with target convo and message
    public func sendMessage(to conversation:String, otherUserEmail:String ,name:String, newMessage:Message,completion:@escaping (Bool)->Void){
        //mesajlara yeni mesaj ekle
        //update ssender latest message
        //update recipient latest message
        //mesaj dizisini almamız lazım
        guard let myEmail = UserDefaults.standard.value(forKey: "email") as? String else{
            completion(false)
            return
        }
        let currentEmail = DatabaseManager.safeEmail(emailAdress: myEmail)
        
        database.child("\(conversation)/messages").observeSingleEvent(of: .value) { [weak self]snapshot in
            guard let strongSelf=self else{return }
            guard var currentMessages = snapshot.value as?  [[String:Any]] else{
                completion(false)
                return
            }
            let messageDate  = newMessage.sentDate
            //database de sadee string saklıyo
            let dateString = ChatViewController.dateFormatter.string(from: messageDate)
            
            var message = " "
            switch newMessage.kind {
                
            case .text(let messageText):
                message=messageText
            case .attributedText(_):
                break
            case .photo(let mediaItem):
                if let targetUrlString = mediaItem.url?.absoluteString {
                    message = targetUrlString
                }
                break
            case .video(let mediaItem):
                if let targetUrlString = mediaItem.url?.absoluteString {
                    message = targetUrlString
                }
                break
            case .location(let locationData):
                let location = locationData.location
                message = "\(location.coordinate.longitude),\(location.coordinate.latitude)"
                break
            case .emoji(_):
                break
            case .audio(_):
                break
            case .contact(_):
                break
            case .linkPreview(_):
                break
            case .custom(_):
                break
            }
            guard let myEmail = UserDefaults.standard.value(forKey: "email") as? String else{
                completion(false)
                return
            }
            let currentUserEmail = DatabaseManager.safeEmail(emailAdress: myEmail)
            
            let newMessageEntry: [String:Any] = [
                "id":newMessage.messageId,
                "type":newMessage.kind.messageKindString,
                "content":message,
                "date":dateString,
                "sender_email":currentUserEmail,
                "is_Read":false,
                "name":name
            ]
            currentMessages.append(newMessageEntry)
            strongSelf.database.child("\(conversation)/messages").setValue(currentMessages) { error, _ in
                guard error == nil else{
                    completion(false)
                    return
                }
                
                strongSelf.database.child("\(currentEmail)/conversations").observeSingleEvent(of: .value) { snapshot in
                  
                    var databaseEntryConversations = [[String:Any]]()
                    let updatedValue :[String:Any] = [
                        "date":dateString,
                        "is_read":false,
                        "message":message
                    ]
                    if var currentUserConversations = snapshot.value as? [[String:Any]] {
                        //we need to create convo entry
                        //find the convoıd ve currentconvoıd
                        var targetConvo:[String:Any]?
                        var position = 0
                        for convoDictionary in currentUserConversations {
                            //son mesajı update edicez
                            if let currentId = convoDictionary["id"] as? String , currentId == conversation{
                                targetConvo = convoDictionary
                                break
                            }
                            position += 1
                        }
                        if var targetConvo = targetConvo{
                            targetConvo["latest_message"] = updatedValue
                            currentUserConversations[position]=targetConvo
                            databaseEntryConversations = currentUserConversations
                        }
                        else{
                            let newConversationData: [String:Any] = [
                                "id": conversation,
                                "other_user_email":DatabaseManager.safeEmail(emailAdress: otherUserEmail),
                                "name":name,
                                "latest_message": updatedValue
                            ]
                            currentUserConversations.append(newConversationData)
                            databaseEntryConversations = currentUserConversations
                        }
                    }
                     else{
                        let newConversationData: [String:Any] = [
                            "id": conversation,
                            "other_user_email":DatabaseManager.safeEmail(emailAdress: otherUserEmail),
                            "name":name,
                            "latest_message": updatedValue
                        ]
                        databaseEntryConversations = [
                           newConversationData
                        ]
                    }
                    
                    strongSelf.database.child("\(currentEmail)/conversations").setValue(databaseEntryConversations) { error, _ in
                        guard error == nil else{
                            completion(false)
                            return
                        }
                        //updates latest message for recipient user
                        strongSelf.database.child("\(otherUserEmail)/conversations").observeSingleEvent(of: .value) { snapshot in
                            //find the convoıd ve currentconvoıd
                            let updatedValue :[String:Any] = [
                                "date":dateString,
                                "is_read":false,
                                "message":message
                            ]
                            var databaseEntryConversations = [[String:Any]]()
                            guard let currentName = UserDefaults.standard.value(forKey: "name") as? String else{
                                return
                            }
                            
                            
                            if var otherUserConversations = snapshot.value as? [[String:Any]]  {
                                var targetConvo:[String:Any]?
                                var position = 0
                                for convoDictionary in otherUserConversations {
                                    //son mesajı update edicez
                                    if let currentId = convoDictionary["id"] as? String , currentId == conversation{
                                        targetConvo = convoDictionary
                                        break
                                    }
                                    position += 1
                                }
                                if var targetConvo = targetConvo{
                                    targetConvo["latest_message"] = updatedValue
                                    
                                      otherUserConversations[position]=targetConvo
                                      databaseEntryConversations = otherUserConversations
                                }
                                else{
                                    //failed to find in current collection
                                    let newConversationData: [String:Any] = [
                                        "id": conversation,
                                        "other_user_email":DatabaseManager.safeEmail(emailAdress: currentEmail),
                                        "name":currentName,
                                        "latest_message": updatedValue
                                    ]
                                    otherUserConversations.append(newConversationData)
                                    databaseEntryConversations = otherUserConversations
                                }
                                
                           }else{
                             //current collection doesnt exist
                               let newConversationData: [String:Any] = [
                                   "id": conversation,
                                   "other_user_email":DatabaseManager.safeEmail(emailAdress: currentEmail),
                                   "name":currentName,
                                   "latest_message": updatedValue
                               ]
                               databaseEntryConversations = [
                                  newConversationData
                               ]
                           }
                           
                            strongSelf.database.child("\(otherUserEmail)/conversations").setValue(databaseEntryConversations) { error, _ in
                                guard error == nil else{
                                    completion(false)
                                    return
                                }
                                //updates latest message for recipient user
                                completion(true)
                            }
                        }
                    }
                }
            }
        }
    }
    
    //databaseden konusmaları silmek için fonksiyon
    public func deleteConversation(conversationId:String,completion:@escaping (Bool)->Void){
        guard let email = UserDefaults.standard.value(forKey: "email") as? String else {return }
        
        let safeEmail = DatabaseManager.safeEmail(emailAdress: email)
        //şuanki kullancının tüm konusmalarını al
        //delete convo in collection with target id
        //reset those convos for the user in database
        
        //kullanıcının konusma klasörü içine girdik
        let ref = database.child("\(safeEmail)/conversations")
        ref.observeSingleEvent(of: .value) { snapshot in
            if var conversations = snapshot.value as? [[String:Any]] {
                var positionToRemove = 0
                for conversation in conversations {
                    if let id = conversation["id"] as? String,
                       id == conversationId{
                        print("found convo to delete")
                        break
                    }
                    positionToRemove+=1
                }
                conversations.remove(at: positionToRemove)
                ref.setValue(conversations) { error, _ in
                    guard error == nil else{
                        completion(false)
                        print("failed to write new convo array")
                        return
                        
                    }
                    
                    print("deleted convo")
                    completion(true)
                }
            }
        }
    }
    
    
    public func conversationExists(with targetRecipientEmail:String,completion : @escaping (Result<String,Error>) -> Void){
        let safeRecipientEmail = DatabaseManager.safeEmail(emailAdress: targetRecipientEmail)
        guard let senderEmail = UserDefaults.standard.value(forKey: "email") as? String else{
            return
        }
        let safeSenderEmail = DatabaseManager.safeEmail(emailAdress: senderEmail)
        
        database.child("\(safeRecipientEmail)/conversations").observeSingleEvent(of: .value, with: { snapshot in
            guard let collection = snapshot.value as? [[String:Any]] else{
                completion(.failure(DatabaseError.failedToFetch))
                return
            }
           
            //iterate and find convo with target sender
            if let conversation = collection.first(where: {
                guard let targetSenderEmail = $0["other_user_email"] as? String else{
                    return false
                }
                return safeSenderEmail == targetSenderEmail
            }) {
                //id yi al
                guard let id = conversation["id"] as? String else{
                    completion(.failure(DatabaseError.failedToFetch))
                    return
                }
                completion(.success(id))
                return
            }
            completion(.failure(DatabaseError.failedToFetch))
            return
            
        })
    }
    
    
}
    
    
    struct ChatAppUser{
        let firstName: String
        let lastName:String
        let emailAdress:String
        
        //realtime database e kaydederken @ ve . yı _ ye cevir dedik çünkü
        //#,@,.,$,[ ] kullanmak yasak
        var safeEmail:String{
            var safeEmail=emailAdress.replacingOccurrences(of: ".", with: "-")
            safeEmail=safeEmail.replacingOccurrences(of: "@", with: "-")
            return safeEmail
        }
        
        var profilePictureFileName:String{
            //beyza-gmail-com_profile_picture.png gibi bir seyin dönmesini istiyoruz
            return "\(safeEmail)_profile_picture.png"
        }
    }

    
