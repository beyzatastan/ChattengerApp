//
//  LoginViewController.swift
//  MessangerApp
//
//  Created by beyza nur on 14.02.2024.
//

import UIKit
import FirebaseAuth
import FirebaseCore
import GoogleSignIn
//import FacebookLogin
import JGProgressHUD

class LoginViewController: UIViewController {
    
    private let spinner = JGProgressHUD(style: .dark)
   
    
    
    //container
    private let scrollView: UIScrollView = {
        let scrollView=UIScrollView()
        scrollView.clipsToBounds=true
        return scrollView
    }()
    
    private let emailField : UITextField = {
        let emailField=UITextField()
        emailField.autocapitalizationType = .none
        emailField.autocorrectionType = .no
        emailField.returnKeyType = .continue
        emailField.layer.cornerRadius = 12
        emailField.layer.borderWidth = 1
        emailField.layer.borderColor = UIColor.lightGray.cgColor
        emailField.placeholder="Email Address..."
        //yazının basındaki boşluk için
        emailField.leftView=UIView(frame: CGRect(x: 0, y: 0, width: 5, height: 0))
        emailField.leftViewMode = . always
        emailField.backgroundColor = .white
        return emailField
    }()
    
    private let passwordField : UITextField = {
        let passwordField=UITextField()
        passwordField.autocapitalizationType = .none
        passwordField.autocorrectionType = .no
        passwordField.returnKeyType = .done
        passwordField.layer.cornerRadius = 12
        passwordField.layer.borderWidth = 1
        passwordField.layer.borderColor = UIColor.lightGray.cgColor
        passwordField.placeholder="Password..."
        //yazının basındaki boşluk için
        passwordField.leftView=UIView(frame: CGRect(x: 0, y: 0, width: 5, height: 0))
        passwordField.leftViewMode = . always
        passwordField.backgroundColor = .white
        passwordField.isSecureTextEntry = true
        return passwordField
    }()
    
    private let loginButton : UIButton = {
        let button = UIButton()
        button.setTitle("Log In", for: .normal)
        button.backgroundColor = .link
        button.setTitleColor(.white, for: .normal)
        button.layer.cornerRadius = 12
        button.layer.masksToBounds  = true
        button.titleLabel?.font = .systemFont(ofSize: 20,weight: .bold)
        return button
    }()
    
    
    private let imageView : UIImageView = {
        let imageView = UIImageView()
        imageView.image=UIImage(named: "logo")
        imageView.contentMode = .scaleAspectFill
        return imageView
        
    }()
    
    // private  let facebookLoginButton = FBLoginButton()
    
    private let googleLogınButton = GIDSignInButton()
    //bildirim gözlemleyicisi oluşturduk
    private var loginObserver : NSObjectProtocol?
    
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        //extension da oluşturdupumuz ismi verdik .didnot
        loginObserver = NotificationCenter.default.addObserver(forName: Notification.Name.didLogInNotification,object:nil,
                                                               queue: .main, using: { [weak self] _ in
            guard let strongSelf = self else{return}
            strongSelf.navigationController?.dismiss(animated: true, completion: nil)
            
        })
        title = "Log In"
        view.backgroundColor = .white
        
        navigationItem.rightBarButtonItem=UIBarButtonItem(title: "Register",style: .done ,target: self, action: #selector(didTapRegister))
        loginButton.addTarget(self, action: #selector(didTapLogin), for: .touchUpInside)
        googleLogınButton.addTarget(self, action: #selector(didtapGoogleLogin), for: .touchUpInside)
        
        
        emailField.delegate = self
        passwordField.delegate = self
        
        //add subviews
        view.addSubview(scrollView)
        scrollView.addSubview(imageView)
        scrollView.addSubview(emailField)
        scrollView.addSubview(passwordField)
        scrollView.addSubview(loginButton)
        // scrollView.addSubview(facebookLoginButton)
        scrollView.addSubview(googleLogınButton)
        
        
    }
    
    //deinitialize yani temizlik işi 
    deinit{
        if let observer=loginObserver{
            NotificationCenter.default.removeObserver(observer)
        }
    }
    
    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        scrollView.frame=view.bounds
        let size = scrollView.width/3
        imageView.frame=CGRect(x: (scrollView.width-size)/2, y: 20, width: size, height: size)
        emailField.frame=CGRect(x: 30, y: imageView.bottom+10, width: scrollView.width-60, height: 52)
        passwordField.frame=CGRect(x: 30, y: emailField.bottom+10, width: scrollView.width-60, height: 52)
        loginButton.frame=CGRect(x: 30, y: passwordField.bottom+10, width: scrollView.width-60, height: 52)
        //        sürekli app ıd yi string gir diyor string girmiş olmama ragmen o yüzden butona bastırmicam
        //        facebookLoginButton.center=scrollView.center
        //        facebookLoginButton.frame.origin.y=loginButton.bottom+20
        googleLogınButton.frame=CGRect(x: 30, y:loginButton.bottom+10,  width: scrollView.width-60, height: 52)
        
        
    }
    
    @objc private func didTapLogin(){
        //klavyeyi kapatmak için
        emailField.resignFirstResponder()
        passwordField.resignFirstResponder()
        
        guard let email = emailField.text , let password = passwordField.text , !email.isEmpty , !password.isEmpty, password.count >= 6  else {
            alertUserLoginError()
            return
        }
        
        //yükleniyor spinner ı
        spinner.show(in: view)
        //firebase log ın
        FirebaseAuth.Auth.auth().signIn(withEmail: email, password: password) { authResults, error in
            guard let results=authResults , error == nil else {
                print("Failed to log in user with email : \(email)")
                return
            }
            DispatchQueue.main.async {
                //yüklenmeyi bitir
                 self.spinner.dismiss()
            }
            
            let user=results.user
            let safeEmail = DatabaseManager.safeEmail(emailAdress: email)
            DatabaseManager.shared.getDataFor(path: safeEmail) { result in
                switch result {
                case .success(let data):
                    guard let userData = data as? [String:Any] ,
                          let firstName = userData["first_name"] as? String,
                          let lastName=userData["last_name"] as? String
                    else{return}
                    UserDefaults.standard.set("\(firstName) \(lastName)", forKey: "name")
                case .failure(let error):
                    print("Failed to read data with error \(error)")
                }
            }
            UserDefaults.standard.set(email, forKey: "email") 
       


        
            print("Logged In User : \(user)")
            self.navigationController?.dismiss(animated: true, completion: nil)
            
        }
        
    }
    
    
    @objc  func didtapGoogleLogin(){
        // Google Sign-In işlemi
        guard let clientID = FirebaseApp.app()?.options.clientID else { return }
        let config = GIDConfiguration(clientID: clientID)
        GIDSignIn.sharedInstance.configuration = config
        
        GIDSignIn.sharedInstance.signIn(withPresenting: self) { result, error in
            guard error == nil else {
                // Google Sign-In işlemi sırasında bir hata oluştu, uygun şekilde işlem yapılmalı
                return
            }
            
            guard let user = result?.user,
                  let idToken = user.idToken?.tokenString
            else {
                // Kullanıcı verisi ve idToken alınamazsa, uygun şekilde işlem yapılmalı
                print("Missing auth object off of google user")
                return
            }
            ///  insert to DATABASE
            print("did sign in with google: \(user)" )
            guard let email = user.profile?.email,
                  let firstName = user.profile?.givenName,
                  let lastName = user.profile?.familyName else{return}
            //image ı bulamk için email ı kullanıcaz
            UserDefaults.standard.set(email, forKey: "email")
            UserDefaults.standard.set("\(firstName) \(lastName)", forKey: "name")

            DatabaseManager.shared.userExists(with: email) { exists in
                if !exists{
                    //insert to database
                    let chatUser=ChatAppUser(firstName: firstName,
                                             lastName: lastName,
                                             emailAdress: email)
                    DatabaseManager.shared.insertUser(with:chatUser) { success in
                        if success {
                            //upload image
                            //profil resmi var mı kontrol edicez
                            if let profile = user.profile {
                                if profile.hasImage {
                                    guard let url = profile.imageURL(withDimension: 200) else {
                                        return
                                    }
                                    guard let url = user.profile?.imageURL(withDimension: 200) else{return}
                                    URLSession.shared.dataTask(with: url) { data, response, error in
                                        guard let data = data else {
                                            return
                                        }
                                        let filename=chatUser.profilePictureFileName
                                        StorageManager.shared.uploadProfilePicture(with: data,fileName: filename) {result in
                                            switch result{
                                            case .success(let downloadUrl) :
                                                UserDefaults.standard.set(downloadUrl, forKey: "profile_picture_url")
                                                print(downloadUrl)
                                            case .failure(let error):
                                                print("storage manager error : \(error)")
                                            }
                                        }
                                    }.resume()
                                    
                                }
                             }
                        }
                    }
                }
            }
            
            // Firebase Authentication credential oluşturma
            let credential = GoogleAuthProvider.credential(withIDToken: idToken,
                                                           accessToken: user.accessToken.tokenString)
            
            // Firebase ile oturum açma işlemi
            FirebaseAuth.Auth.auth().signIn(with: credential) { result, error in
                if let error = error {
                    // Firebase ile oturum açma işlemi sırasında bir hata oluştu, uygun şekilde işlem yapılmalı
                    print("Failed to sign in with Firebase: \(error)")
                    return
                }
                // Firebase ile oturum açma işlemi başarılı
                print("Signed in with Firebase")
                // self.navigationController?.dismiss(animated: true, completion: nil)
                ///sadece yukardakini de kullanabilirdim ama ek olarak notification kullanmayı da ggöstermek istedim
                /// bu sayede log in yapınca ana sayfaya geciş yaptık
                NotificationCenter.default.post(name: .didLogInNotification, object: nil)
                
            }
            
            
        }
    }
    
    
    func alertUserLoginError(){
        let alert=UIAlertController(title: "Wopps", message: "Please enter all information for login.", preferredStyle: UIAlertController.Style.alert)
        
        alert.addAction(UIAlertAction(title: "Dismiss", style: UIAlertAction.Style.cancel, handler: nil))
        present(alert,animated: true)
    }
    
    
    @objc private func didTapRegister(){
        let vc=RegisterViewController()
        vc.title="Create Account"
        navigationController?.pushViewController(vc, animated: true)
    }
    
    
}

extension LoginViewController : UITextFieldDelegate{
    
    func textFieldShouldReturn(_ textfield:UITextField) -> Bool {
        if textfield == emailField {
            passwordField.becomeFirstResponder()
        } else if textfield == passwordField {
            didTapLogin()
        }
        return true
    }
    
    
}
