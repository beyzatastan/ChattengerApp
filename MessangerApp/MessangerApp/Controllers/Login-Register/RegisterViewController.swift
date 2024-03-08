//
//  RegisterViewController.swift
//  MessangerApp
//
//  Created by beyza nur on 14.02.2024.
//

import UIKit
import FirebaseAuth
import JGProgressHUD

class RegisterViewController: UIViewController {
    
    private let spinner = JGProgressHUD(style: .dark)
    
    //container
    private let scrollView: UIScrollView = {
        let scrollView=UIScrollView()
        scrollView.clipsToBounds=true
        return scrollView
    }()
    
    private let firstNameField : UITextField = {
        let field=UITextField()
        field.autocapitalizationType = .none
        field.autocorrectionType = .no
        field.returnKeyType = .continue
        field.layer.cornerRadius = 12
        field.layer.borderWidth = 1
        field.layer.borderColor = UIColor.lightGray.cgColor
        field.placeholder="First Name..."
        //yazının basındaki boşluk için
        field.leftView=UIView(frame: CGRect(x: 0, y: 0, width: 5, height: 0))
        field.leftViewMode = . always
        field.backgroundColor = .white
        return field
    }()
    
    private let lastNameField : UITextField = {
        let field=UITextField()
        field.autocapitalizationType = .none
        field.autocorrectionType = .no
        field.returnKeyType = .continue
        field.layer.cornerRadius = 12
        field.layer.borderWidth = 1
        field.layer.borderColor = UIColor.lightGray.cgColor
        field.placeholder="Last Name..."
        //yazının basındaki boşluk için
        field.leftView=UIView(frame: CGRect(x: 0, y: 0, width: 5, height: 0))
        field.leftViewMode = . always
        field.backgroundColor = .white
        return field
    }()
    
    private let emailField : UITextField = {
        let field=UITextField()
        field.autocapitalizationType = .none
        field.autocorrectionType = .no
        field.returnKeyType = .continue
        field.layer.cornerRadius = 12
        field.layer.borderWidth = 1
        field.layer.borderColor = UIColor.lightGray.cgColor
        field.placeholder="Email Address..."
        //yazının basındaki boşluk için
        field.leftView=UIView(frame: CGRect(x: 0, y: 0, width: 5, height: 0))
        field.leftViewMode = . always
        field.backgroundColor = .white
        return field
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
    
    
    private let registerButton : UIButton = {
        let button = UIButton()
        button.setTitle("Register", for: .normal)
        button.backgroundColor = .systemGreen
        button.setTitleColor(.white, for: .normal)
        button.layer.cornerRadius = 12
        button.layer.masksToBounds  = true
        button.titleLabel?.font = .systemFont(ofSize: 20,weight: .bold)
        return button
    }()
    
    
    
    private let imageView : UIImageView = {
        let imageView = UIImageView()
        imageView.image=UIImage(systemName: "person.circle")
        imageView.tintColor = .gray
        imageView.contentMode = .scaleAspectFill
        imageView.layer.masksToBounds=true
        imageView.layer.borderWidth=2
        imageView.layer.borderColor = UIColor.lightGray.cgColor
        return imageView
        
    }()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        title = "Register"
        view.backgroundColor = .white
        
        
        registerButton.addTarget(self, action: #selector(registerButtonTapped), for: .touchUpInside)
        
        
        emailField.delegate = self
        passwordField.delegate = self
        
        
        //add subviews
        view.addSubview(scrollView)
        scrollView.addSubview(imageView)
        scrollView.addSubview(emailField)
        scrollView.addSubview(passwordField)
        scrollView.addSubview(registerButton)
        scrollView.addSubview(firstNameField)
        scrollView.addSubview(lastNameField)
        
        imageView.isUserInteractionEnabled=true
        scrollView.isUserInteractionEnabled = true
        
        let gesture=UITapGestureRecognizer(target: self,
                                           action: #selector(didTapChangeProfie))
        imageView.addGestureRecognizer(gesture)
    }
    
    @objc private func didTapChangeProfie(){
        //kullanıcı resmi oluşturma
        presentPhotoActionSheet()
    }
    
    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        scrollView.frame=view.bounds
        let size = scrollView.width/3
        imageView.frame=CGRect(x: (scrollView.width-size)/2, y: 20, width: size, height: size)
        //resmi yuvarlak gösterir
        imageView.layer.cornerRadius=imageView.width/2.0
        firstNameField.frame=CGRect(x: 30, y: imageView.bottom+10, width: scrollView.width-60, height: 52)
        lastNameField.frame=CGRect(x: 30, y: firstNameField.bottom+10, width: scrollView.width-60, height: 52)
        emailField.frame=CGRect(x: 30, y: lastNameField.bottom+10, width: scrollView.width-60, height: 52)
        passwordField.frame=CGRect(x: 30, y: emailField.bottom+10, width: scrollView.width-60, height: 52)
        registerButton.frame=CGRect(x: 30, y: passwordField.bottom+10, width: scrollView.width-60, height: 52)
        
        
    }
    
    @objc private func registerButtonTapped(){
        
        //klavyeyi kapatmak için
        emailField.resignFirstResponder()
        passwordField.resignFirstResponder()
        firstNameField.resignFirstResponder()
        lastNameField.resignFirstResponder()
        
        
        guard  let firstName=firstNameField.text, let lastName=lastNameField.text  ,let email = emailField.text , let password = passwordField.text , !email.isEmpty , !password.isEmpty, !lastName.isEmpty , !firstName.isEmpty, password.count >= 6  else {
            alertUserLoginError()
            return
        }
        spinner.show(in: view)
        
        
        //FIREBASE LOG IN
        
        DatabaseManager.shared.userExists(with: email) { exists in
            guard !exists else{
                //kullanıcı zaten varsa
                self.alertUserLoginError(message: "Looks like a user accounnt for this email address already exists.")
                return
            }
            DispatchQueue.main.async {
                //yüklenmeyi bitir
                self.spinner.dismiss()
            }
            //eğer kullanıcı yoksa yeni yarat
            FirebaseAuth.Auth.auth().createUser(withEmail: email, password: password) { authresults, error in
                guard authresults != nil ,error == nil else {
                    print("error creating user")
                    return
                }
                let chatUser=ChatAppUser(firstName: firstName,
                                         lastName: lastName,
                                         emailAdress: email)
                DatabaseManager.shared.insertUser(with:chatUser , completion: { success in
                    if success {
                        ///upload img
                        guard let image = self.imageView.image ,
                                let data = image.pngData() else {
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
                    }
                })
                self.navigationController?.dismiss(animated: true,completion: nil)
                
                
            }
        }
        
        
        
    }
    
    func alertUserLoginError(message:String = "Please enter all information to create a new account."){
        let alert=UIAlertController(title: "Wopps", message: message, preferredStyle: UIAlertController.Style.alert)
        
        alert.addAction(UIAlertAction(title: "Dismiss", style: UIAlertAction.Style.cancel, handler: nil))
        present(alert,animated: true)
    }
    
    
    
}

extension RegisterViewController : UITextFieldDelegate{
    func textFieldShouldReturn(_ textfield:UITextField) -> Bool {
        if textfield == emailField {
            passwordField.becomeFirstResponder()
        } else if textfield == passwordField {
            registerButtonTapped()
        }
        return true
    }
    
    
}


extension RegisterViewController :UIImagePickerControllerDelegate,UINavigationControllerDelegate{
    
    func presentPhotoActionSheet(){
        let actionSheet=UIAlertController(title: "Profile Picture", message: "How would you like to select a picture for profile ?", preferredStyle: .actionSheet)
        
        actionSheet.addAction(UIAlertAction(title: "Cancel", style: .cancel, handler: nil))
        actionSheet.addAction(UIAlertAction(title: "Take Photo", style: .default, handler: {[weak self] _ in
            self?.presentCamere()
        }))
        actionSheet.addAction(UIAlertAction(title: "Choose Photo", style: .default, handler: { [weak self] _ in
            self?.presentPhotoPicker()
        }))
        
        present(actionSheet,animated: true)
        
    }
    
    
    func presentCamere(){
        let vc=UIImagePickerController()
        vc.sourceType = .camera
        vc.delegate = self
        vc.allowsEditing = true
        present(vc,animated: true)
    }
    
    func presentPhotoPicker(){
        let vc=UIImagePickerController()
        vc.sourceType = .photoLibrary
        vc.delegate = self
        vc.allowsEditing = true
        present(vc,animated: true)
    }
    
    
    func imagePickerController(_ picker: UIImagePickerController, didFinishPickingMediaWithInfo info: [UIImagePickerController.InfoKey : Any]) {
        picker.dismiss(animated: true,completion: nil)
        
        guard let selectedImage=info[UIImagePickerController.InfoKey.editedImage] as? UIImage else{return}
        
        self.imageView.image=selectedImage
    }
    
    func imagePickerControllerDidCancel(_ picker: UIImagePickerController) {
        picker.dismiss(animated: true,completion: nil)
        
    }
}
