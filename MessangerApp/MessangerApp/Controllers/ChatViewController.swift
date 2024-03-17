//
//  ChatViewController.swift
//  MessangerApp
//
//  Created by beyza nur on 15.02.2024.
//

import UIKit
import MessageKit
import InputBarAccessoryView
import SDWebImage
import AVFoundation
import AVKit
import CoreLocation


final class ChatViewController:MessagesViewController {
    
    private var senderPhotoURL: URL?
    private var otherUserPhotoURL : URL?
    
    public static let dateFormatter : DateFormatter = {
       let formatter=DateFormatter()
        formatter.dateStyle = .medium
        formatter.timeStyle = .long
        formatter.locale = .current
        return formatter
    }()
     
    public let otherUserEmail : String
    private var conversationId : String?

    public var isNewConversation = false
    
    
    private var messages = [MessageType]()
    
    private var selfSender : Sender? {
        //uygulamanın veritabanında email diye kaydettiğimiz veriyi aldık
       guard let  email=UserDefaults.standard.value(forKey: "email") as? String else {
            return nil
        }
        let safeEmail = DatabaseManager.safeEmail(emailAdress: email)
        
       return  Sender(photoURL: " ", senderId:safeEmail , displayName: "Me")
        
    }
   
    //consturctor oluşturduk
    init(with email : String, id :String?){
        self.conversationId = id
        self.otherUserEmail = email
        super.init(nibName: nil, bundle: nil)
        
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    

    
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        
        messagesCollectionView.messagesDataSource=self
        messagesCollectionView.messagesLayoutDelegate=self
        messagesCollectionView.messagesDisplayDelegate=self
        messagesCollectionView.messageCellDelegate=self
        messageInputBar.delegate = self
        setUpInputButton()
        //bunu yazmazsam mesajlar gözükmez
        
        messagesCollectionView.reloadData()
    }
    private func setUpInputButton(){
        let button = InputBarButtonItem()
        button.setSize(CGSize(width: 35, height: 35), animated: false)
        button.setImage(UIImage(systemName: "paperclip"), for: .normal)
        button.onTouchUpInside { [weak self] _ in
            self?.presentInputActionSheet()
        }
        messageInputBar.setLeftStackViewWidthConstant(to: 36, animated: false)
        messageInputBar.setStackViewItems([button], forStack: .left, animated: false)
    }
    
    private func presentInputActionSheet(){
        let actionSheet = UIAlertController(title: "Attach Media",
                                            message: "What would you attach ?", preferredStyle: .actionSheet)
        actionSheet.addAction(UIAlertAction(title: "Photo", style: .default, handler: { [weak self] _ in
            self?.presentPhotoInputActionSheet()
        }))
        actionSheet.addAction(UIAlertAction(title: "Video", style: .default, handler: { [weak self] _ in
            self?.presentVideoInputActionSheet()
        }))
        actionSheet.addAction(UIAlertAction(title: "Audio", style: .default, handler: { [weak self] _ in
            
        }))
        actionSheet.addAction(UIAlertAction(title: "Location", style: .default, handler: { [weak self] _ in
            self?.presentLocationPicker()
        }))
        actionSheet.addAction(UIAlertAction(title: "Cancel", style: .cancel, handler:nil))
        
        present(actionSheet,animated: true)
    }
    
    private func presentLocationPicker(){
        let vc = LocationPickerViewController(coordinates: nil)
        vc.title = "Pick Location"
        vc.navigationItem.largeTitleDisplayMode = .never
        vc.completion = {[weak self] selectedCoordinates in
            guard let strongSelf = self else{
                return
            }
            
            guard let messageId = strongSelf.createMessageId(),
                  let conversationId = strongSelf.conversationId,
                  let name = strongSelf.title,
                  let selfSender = strongSelf.selfSender
            else{
          
                return
            }
            
            let longitude:Double = selectedCoordinates.longitude
            let latitude:Double = selectedCoordinates.latitude
            
            print("longitude:\(longitude) , latitude:\(latitude)")
            
            let location = Location(location: CLLocation(latitude: latitude, longitude: longitude), size: .zero)
            let message=Message(sender: selfSender,
                                messageId: messageId,
                                sentDate: Date(),
                                kind: .location(location))
            
            
            DatabaseManager.shared.sendMessage(to: conversationId,
                                               otherUserEmail: strongSelf.otherUserEmail,
                                               name: name, newMessage: message) { success in
                
                if success {
                    print("sent location message")
                }else{
                    print("failed to send message")
                }
            }

        }
        navigationController?.pushViewController(vc, animated: true)
    }

    
    private func presentPhotoInputActionSheet(){
        let actionSheet = UIAlertController(title: "Attach Photo",
                                            message: "Where would you like to attach a photo from ?", preferredStyle: .actionSheet)
        actionSheet.addAction(UIAlertAction(title: "Camera", style: .default, handler: { [weak self] _ in
         let picker = UIImagePickerController()
            picker.sourceType = .camera
            picker.delegate = self
            picker.allowsEditing = true
            self?.present(picker,animated: true)
        }))
        actionSheet.addAction(UIAlertAction(title: "Photo Library", style: .default, handler: { [weak self] _ in
            let picker = UIImagePickerController()
               picker.sourceType = .photoLibrary
               picker.delegate = self
               picker.allowsEditing = true
               self?.present(picker,animated: true)
        }))
        actionSheet.addAction(UIAlertAction(title: "Cancel", style: .cancel, handler:nil))
        
        present(actionSheet,animated: true)
    }
    
    private func presentVideoInputActionSheet(){
        let actionSheet = UIAlertController(title: "Attach Video",
                                            message: "Where would you like to attach a video from ?", preferredStyle: .actionSheet)
        actionSheet.addAction(UIAlertAction(title: "Camera", style: .default, handler: { [weak self] _ in
         let picker = UIImagePickerController()
            picker.sourceType = .camera
            picker.delegate = self
            picker.allowsEditing = true
            self?.present(picker,animated: true)
        }))
        actionSheet.addAction(UIAlertAction(title: "Library", style: .default, handler: { [weak self] _ in
            let picker = UIImagePickerController()
            picker.sourceType = .photoLibrary
            picker.delegate = self
            picker.mediaTypes = ["public.movie"]
            picker.videoQuality = .typeMedium
            picker.allowsEditing = true
            self?.present(picker,animated: true)
        }))
        actionSheet.addAction(UIAlertAction(title: "Cancel", style: .cancel, handler:nil))
        
        present(actionSheet,animated: true)
    }
    
    
    private func listenForMessages(id :String ,shouldScrollToBottom : Bool ){
        DatabaseManager.shared.getAllMessagesForConversation(with: id) { [weak self] result in
            switch result {
            case .success(let messages) :
                guard !messages.isEmpty else {
                    return
                }
                self?.messages = messages
                DispatchQueue.main.async {
                    self?.messagesCollectionView.reloadDataAndKeepOffset()
                    
                    
                }
            case .failure(let error) :
                print("failed to get messages \(error)")
            }
        }
    }
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        messageInputBar.inputTextView.becomeFirstResponder()
        if let conversationId = conversationId{
            listenForMessages(id:conversationId , shouldScrollToBottom : true)
        }
    }
}

extension ChatViewController:UIImagePickerControllerDelegate , UINavigationControllerDelegate{
    func imagePickerControllerDidCancel(_ picker: UIImagePickerController) {
        picker.dismiss(animated: true, completion: nil)
    }
    func imagePickerController(_ picker: UIImagePickerController, didFinishPickingMediaWithInfo info: [UIImagePickerController.InfoKey : Any]) {
        picker.dismiss(animated: true,completion: nil)
        guard let messageId = createMessageId(),
              let conversationId = conversationId,
              let name = self.title,
              let selfSender = selfSender
        else{
      
            return
        }
        
        //resim gönderiyorsak
        if let image = info[.editedImage] as? UIImage,let imageData = image.pngData(){
            let fileName = "photo_message_" + messageId.replacingOccurrences(of: " ", with: "-") + ".png"
            //upload ımage
            StorageManager.shared.uploadMessagePhoto(with: imageData, fileName: fileName) { [weak self] result in
                guard let strongself = self else{return}
                switch result{
                case .success(let urlString) :
                //mesajı göndermeye hazırız
                    print("uploaded message photos :\(urlString)")
                    guard let url=URL(string: urlString) ,
                          let placeholder = UIImage(systemName: "plus") else{return}
                    
                    let media = Media(url:url,image:nil,placeholderImage: placeholder, size: .zero)
                    let message=Message(sender: selfSender,
                                        messageId: messageId,
                                        sentDate: Date(),
                                        kind: .photo(media))
                    
                    
                    DatabaseManager.shared.sendMessage(to: conversationId,
                                                       otherUserEmail: strongself.otherUserEmail,
                                                       name: name, newMessage: message) { success in
                        
                        if success {
                            print("sent photo message")
                        }else{
                            print("failed to send message")
                        }
                    }
      
                case .failure(let error):
                    print("message photo upload error :\(error)")
                }
            }
        }
        //video gönderiyırsak
        else if let videoUrl = info[.mediaURL] as? URL{
            let fileName = "photo_message_" + messageId.replacingOccurrences(of: " ", with: "-") + ".mov"
            //upload video
            StorageManager.shared.uploadMessageVideo(with: videoUrl, fileName: fileName) { [weak self] result in
                guard let strongself = self else{return}
                switch result{
                case .success(let urlString) :
                //mesajı göndermeye hazırız
                    print("uploaded message videos :\(urlString)")
                    guard let url=URL(string: urlString) ,
                          let placeholder = UIImage(systemName: "plus") else{return}
                    
                    let media = Media(url:url,image:nil,placeholderImage: placeholder, size: .zero)
                    let message=Message(sender: selfSender,
                                        messageId: messageId,
                                        sentDate: Date(),
                                        kind: .video(media))
                    
                    
                    DatabaseManager.shared.sendMessage(to: conversationId,
                                                       otherUserEmail: strongself.otherUserEmail,
                                                       name: name, newMessage: message) { success in
                        
                        if success {
                            print("sent video message")
                        }else{
                            print("failed to send message")
                        }
                    }
      
                case .failure(let error):
                    print("message photo upload error :\(error)")
                }
            }
        }
        
    }
}
extension ChatViewController : InputBarAccessoryViewDelegate{
    func inputBar(_ inputBar: InputBarAccessoryView, didPressSendButtonWith text: String) {
        //mesaj boş değilse
        guard !text.replacingOccurrences(of: " ", with: "").isEmpty ,
              let selfSender = self.selfSender ,
          let messageId=createMessageId()  else{
            return
        }
        
        print("Sending: \(text)")
        let message=Message(sender: selfSender,
                            messageId: messageId,
                            sentDate: Date(),
                            kind: .text(text))
        
        //mesajı gönder
        if isNewConversation{
            //eğer yeni bi konuşmaysa
            //database de cr4eate et
            
            DatabaseManager.shared.createNewConversation(with: otherUserEmail,name:self.title ?? "User" , firstMessage: message, completion: { [weak self] success in
                if success {
                    print("message sent")
                    self?.isNewConversation = false
                    let newConvoId="conversastion_\(message.messageId)"
                    self?.conversationId = newConvoId
                    self?.listenForMessages(id: newConvoId, shouldScrollToBottom: true)
                    //mesajı gönderdikten sonra mesaj kısmını temizler
                    self?.messageInputBar.inputTextView.text = nil
                }
                else{
                    print("failed to send")
                }})
            
            
        }else{
            //değilse databasedeki convoya ekle
            guard let conversationId = conversationId ,
            let name = self.title
            else{return}
            DatabaseManager.shared.sendMessage(to: conversationId, otherUserEmail:otherUserEmail , name: name  ,newMessage: message) { success in
                if success {
                    print("message sent")
                    self.messageInputBar.inputTextView.text = nil

                }else{
                    print("failed to send")
                }
            }
        }
    }
    
    
    private func createMessageId() ->String? {
        //date,other user email,sender email,random int
        guard let currentUserEmail = UserDefaults.standard.value(forKey: "email") as? String else{
            return nil
        }
        //normal email i kullanamayız database e eklerken
        let safeEmail=DatabaseManager.safeEmail(emailAdress: currentUserEmail)
        let dateString = Self.dateFormatter.string(from: Date())
        let newIdentifier = "\(otherUserEmail)_\(safeEmail)_\(dateString)"
        print("created message id: \(newIdentifier)")
        return newIdentifier
        
    }
    
}

extension ChatViewController :  MessagesDataSource , MessagesLayoutDelegate,MessagesDisplayDelegate{
    
    func numberOfSections(in messagesCollectionView: MessageKit.MessagesCollectionView) -> Int {
        return messages.count
    }
    
    
    var currentSender: MessageKit.SenderType {
        if let sender = selfSender {
            return sender
        }
        fatalError("Self Sender is nil,email should be crashed")
        
    }
    
    func messageForItem(at indexPath: IndexPath, in messagesCollectionView: MessageKit.MessagesCollectionView) -> MessageKit.MessageType {
        return messages[indexPath.section]
        
    }
    ///image message ı görmemiz için download ve update işlerini burda yapıxaz
    func configureMediaMessageImageView(_ imageView: UIImageView, for message: MessageType, at indexPath: IndexPath, in messagesCollectionView: MessagesCollectionView) {
        guard let message = message as? Message else{
            return
        }
        switch message.kind{
        case .photo(let media):
            guard let imageUrl = media.url else{
                return
            }
            imageView.sd_setImage(with: imageUrl, completed: nil)
        default:
            break
        }
    }
    //mesaj balonunun regi
    func backgroundColor(for message: MessageType, at indexPath: IndexPath, in messagesCollectionView: MessagesCollectionView) -> UIColor {
        let sender =  message.sender
        if sender.senderId == selfSender?.senderId {
            //kendi mesajımız
            return .systemPurple
        }
        return .lightGray
    }
    
    //sohbette pp kıamında r4esmimizin gözükmesi için
    func configureAvatarView(_ avatarView: AvatarView, for message: MessageType, at indexPath: IndexPath, in messagesCollectionView: MessagesCollectionView) {
        //mesaj kime ait
        let sender = message.sender
        if sender.senderId == selfSender?.senderId{
            //kendi resmimizi göstericez
            if let  currentUserImageURL = self.senderPhotoURL{
                avatarView.sd_setImage(with: currentUserImageURL,completed: nil)
            }else{
                //url i çek
                guard let email = UserDefaults.standard.value(forKey: "email") as? String else {return}
                let safeEmail = DatabaseManager.safeEmail(emailAdress: email)
                let path = "images/\(safeEmail)_profile_picture.png"
                StorageManager.shared.downloadURL(for: path , completion: { [weak self] result in
                    switch result {
                    case .success(let url):
                        self?.senderPhotoURL = url
                        DispatchQueue.main.async{
                            avatarView.sd_setImage(with: url,completed: nil)
                        }
                    case .failure(let error):
                        print("\(error)")
                    }
                })
            }
        }else{
            //karşı tarfaın resmini
            if let  otherUserImageURL = self.otherUserPhotoURL{
                avatarView.sd_setImage(with: otherUserPhotoURL,completed: nil)
            }else{
                //resmi çek
               let email = self.otherUserEmail
                let safeEmail = DatabaseManager.safeEmail(emailAdress: email)
                let path = "images/\(safeEmail)_profile_picture.png"
                StorageManager.shared.downloadURL(for: path , completion: { [weak self] result in
                    switch result {
                    case .success(let url):
                        self?.otherUserPhotoURL = url
                        DispatchQueue.main.async{
                            avatarView.sd_setImage(with: url,completed: nil)
                        }
                    case .failure(let error):
                        print("\(error)")
                    }
                })
            }
        }
        
    }
}

extension ChatViewController:MessageCellDelegate{
    
    func didTapMessage(in cell: MessageCollectionViewCell) {
        guard let indexPath = messagesCollectionView.indexPath(for: cell) else{return}

        let message = messages[indexPath.section]
            
            switch message.kind{
            case .location(let locationData):
                let coordinates = locationData.location.coordinate
                //bu sayfaya gitsin istiyoruz
                let vc = LocationPickerViewController(coordinates: coordinates)
                vc.title = "Location"
                self.navigationController?.pushViewController(vc, animated: true)
            
                    default:
                break
            }
    }
    
    func didTapImage(in cell: MessageCollectionViewCell) {
        //resme tıklandığında
        guard let indexPath = messagesCollectionView.indexPath(for: cell) else{return}

        let message = messages[indexPath.section]
            
            switch message.kind{
            case .photo(let media):
                guard let imageUrl = media.url else{
                    return
                }
                //bu sayfaya gitsin istiyoruz
               let vc = PhotoViewerViewController(with: imageUrl)
                self.navigationController?.pushViewController(vc, animated: true)
                
            case .video(let media):
                guard let videoUrl = media.url else{
                    return
                }
                let vc = AVPlayerViewController()
                vc.player = AVPlayer(url: videoUrl)
                present(vc,animated: true)
                    default:
                break
            }
    }
    
}



