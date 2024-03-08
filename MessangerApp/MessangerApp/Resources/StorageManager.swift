//
//  StorageManager.swift
//  MessangerApp
//
//  Created by beyza nur on 16.02.2024.
//

import Foundation
import FirebaseStorage

//kullanıcının resmini kaydetek için
class StorageManager {
    
    static let shared = StorageManager()
    
    private let storage = Storage.storage().reference()
    
    /*
     /images/beyza-gmail-com_profile_picture.png
     */
    
    public typealias UploadPictureCompletion = (Result<String,Error>) -> Void
    
    ///upload pics to firebase strorage and returns completion with url string to dowload
    public func uploadProfilePicture(with data: Data , fileName : String ,completion : @escaping UploadPictureCompletion ){
        //storage ın içinde bir section oluştrduk
        storage.child("images/\(fileName)").putData(data, metadata: nil) { metadata, error in
            guard error == nil else {
                //failed
                print("failed to upload data to firebase for picture")
                completion (.failure(StorageError.failedToUpload))
                return
            }
            
            //resmi çekmeye çalışşıyoruz
            self.storage.child("images/\(fileName)").downloadURL { url, error in
                guard let url = url else{
                    print("failed to get download url")
                    completion(.failure(StorageError.failedToGetDownloadUrl))
                    return
                }
                
                //eğer url i alabildiysek
                let urlString = url.absoluteString
                print("download url returned: \(urlString)")
                completion(.success(urlString))
            }
        }
    }
    ///upload ımage that will be sent in cono message
    public func uploadMessagePhoto(with data: Data , fileName : String ,completion : @escaping UploadPictureCompletion ){
        //storage ın içinde bir section oluştrduk
        print("Starting to upload message photo")
        //yeni klasor oluşturduk resmi koymak için
        storage.child("message_images/\(fileName)").putData(data, metadata: nil) { [weak self] metadata, error in
            guard error == nil else {
                //failed
                print("failed to upload data to firebase for picture")
                completion (.failure(StorageError.failedToUpload))
                return
            }
            
            //resmi çekmeye çalışşıyoruz
            self?.storage.child("message_images/\(fileName)").downloadURL { url, error in
                guard let url = url else{
                    print("failed to get download url")
                    print("buraya girmiyo")
                    completion(.failure(StorageError.failedToGetDownloadUrl))
                    return
                }
                
                //eğer url i alabildiysek
                let urlString = url.absoluteString
                print("buraya girmiyooo")
                print("download url returned: \(urlString)")
                completion(.success(urlString))
            }
        }
    }
    
    public func uploadMessageVideo(with fileUrl:URL , fileName : String ,completion : @escaping UploadPictureCompletion ){
        //storage ın içinde bir section oluştrduk
        print("Starting to upload message photo")
        //yeni klasor oluşturduk resmi koymak için
        storage.child("message_videos/\(fileName)").putFile(from: fileUrl, metadata: nil) { [weak self] metadata, error in
            guard error == nil else {
                //failed
                print("failed to upload video to firebase for picture")
                completion (.failure(StorageError.failedToUpload))
                return
            }
            
            //resmi çekmeye çalışşıyoruz
            self?.storage.child("message_videos/\(fileName)").downloadURL { url, error in
                guard let url = url else{
                    print("failed to get download video")
                    completion(.failure(StorageError.failedToGetDownloadUrl))
                    return
                }
                
                //eğer url i alabildiysek
                let urlString = url.absoluteString
                print("buraya girmiyooo")
                print("download url returned: \(urlString)")
                completion(.success(urlString))
            }
        }
    }
    
    //kendi errorlarımız oluşturuyoruz
    public enum StorageError : Error {
        case failedToUpload
        case failedToGetDownloadUrl
    }
    
    
    public func downloadURL(for path: String, completion : @escaping (Result <URL,Error>) -> Void){
       // let reference = storage.child(path)
        let reference = storage.child("\(path)")
        
        reference.downloadURL { url, error in
            guard let url = url,error == nil else {
                completion(.failure(StorageError.failedToGetDownloadUrl))
                print("Failed to download URL: \(error?.localizedDescription ?? "Unknown error")")
                return
            }
            completion(.success(url))
        }
    }
}
