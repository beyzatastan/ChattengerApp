//
//  ProfileViewController.swift
//  MessangerApp
//
//  Created by beyza nur on 14.02.2024.
//

import UIKit
import FirebaseAuth
import GoogleSignIn
import SDWebImage

final class ProfileViewController: UIViewController{
    
    @IBOutlet weak var tableView: UITableView!
    var data=[ProfileViewModel]()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        tableView.register(ProfileTableViewCell.self, forCellReuseIdentifier:ProfileTableViewCell.indetifier)
        //ekranın altındaki navbar ın gözükmesi için
        navigationController?.navigationBar.isHidden=false
        
        data.append(ProfileViewModel(viewModelType: .info, title: "Name : \(UserDefaults.standard.value(forKey: "name") as? String ?? "No Name")", handler:nil ))
        data.append(ProfileViewModel(viewModelType: .info, title: "E-mail : \(UserDefaults.standard.value(forKey: "email") as? String ?? "No Email")", handler:nil ))
       
        data.append(ProfileViewModel(viewModelType: .logout, title: "Log Out", handler:{ [weak self] in
            guard let strongSelf = self else {return}
            let actionSheet=UIAlertController(title: "", message: "", preferredStyle: .actionSheet)
            //çıkış yapmak için
            actionSheet.addAction(UIAlertAction(title: "Log Out", style: .destructive, handler: { [weak self] _ in
                //log out facebook
                // FBSDKLoginKit.LoginManager().logOut()

                
                //google log out
                GIDSignIn.sharedInstance.signOut()
                let firebaseAuth = Auth.auth()
                do {
                    try firebaseAuth.signOut()
                } catch let signOutError as NSError {
                    print("Error signing out: %@", signOutError)
                }
                
                do{
                    try FirebaseAuth.Auth.auth().signOut()
                    let vc=LoginViewController()
                    let nav=UINavigationController(rootViewController: vc)
                    //eğer bunu yazmazsak sayfa pop in şekilde gelir ve kullanıcı onu aşağı sürükleyip geçebilir
                    nav.modalPresentationStyle = .fullScreen
                    strongSelf.present(nav,animated: true)
                }catch{
                    print("Failed to log out.")
                }
            }))
            //iptal etmek için
            actionSheet.addAction(UIAlertAction(title: "Cancel", style: .cancel, handler: nil))
            strongSelf.present(actionSheet,animated: true)
            
        } ))

        //tableview un cell ine identifier ekledik
        tableView.register(UITableViewCell.self, forCellReuseIdentifier: "cell")
        tableView.delegate=self
        tableView.dataSource=self
        tableView.tableHeaderView = createTableHeader()
        
        
        
    }
    //\(safeEmail)_profile_picture.png
    func createTableHeader() -> UIView? {
        guard let email = UserDefaults.standard.value(forKey: "email") as? String else{
            return nil
        }
        let safeEmail=DatabaseManager.safeEmail(emailAdress: email)
        let filename = safeEmail + "_profile_picture.png"
        let path="images/"+filename
        
        let headerView=UIView(frame: CGRect(x: 0, y: 0, width: self.view.width, height: 300))
        headerView.backgroundColor = .link
        let imageView = UIImageView(frame: CGRect(x: (headerView.width-150)/2, y: 75, width: 150, height: 150))
        
        imageView.contentMode = .scaleAspectFill
        imageView.backgroundColor = .white
        imageView.layer.borderColor = UIColor.white.cgColor
        imageView.layer.borderWidth = 3
        //yuvarlak yapıyo
        imageView.layer.cornerRadius = imageView.width/2
        imageView.layer.masksToBounds = true
        headerView.addSubview(imageView)
        
        StorageManager.shared.downloadURL(for: path) { result in
            switch result {
            case .success(let url) :
                imageView.sd_setImage(with: url,completed: nil)
                // self?.downloadImage(imageView: imageView, url: url)
            case .failure(let error) :
                print("Failed to download url : \(error.localizedDescription)")
                
            }
        }
        
        return headerView
        
    }
}
   
    /* func downloadImage(imageView: UIImageView,url : URL){
      //  imageView.sd_setImage(with: url,completed: nil)
        //sd web image kulandığımız için fonksiyona ve alttakileregerek yok
       
        URLSession.shared.dataTask(with: url) { data, response, error in
            guard let data = data , error == nil else{
                return
            }
            
            //viewda değişecek her şeyin mainde olması gerektiği için bunu kullanmak zorundayız
            DispatchQueue.main.async {
                let image = UIImage(data: data)
                imageView.image=image
                
                self.tableView.reloadData()
                
            }
        }.resume()  */

extension ProfileViewController:UITableViewDelegate, UITableViewDataSource {
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return data.count
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let viewModel = data[indexPath.row]
        let cell = tableView.dequeueReusableCell(withIdentifier: ProfileTableViewCell.indetifier, for: indexPath) as! ProfileTableViewCell
        cell.setUp(with: viewModel)
        return cell
    }
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        tableView.deselectRow(at: indexPath, animated: true)
        data[indexPath.row].handler?()
        
        
    }
}

class ProfileTableViewCell:UITableViewCell{
    
    static let indetifier = "ProfileTableViewCell"
    public func setUp(with viewModel : ProfileViewModel){
        self.textLabel?.text = viewModel.title
        switch viewModel.viewModelType {
        case .info:
            textLabel?.textAlignment = .left
            //cell e tıkllanmasını önlüyor 
           selectionStyle = .none
        case .logout:
            textLabel?.textColor = .red
            textLabel?.textAlignment = .center
        }
    }
}
