//
//  ViewController.swift
//  MessangerApp
//
//  Created by beyza nur on 14.02.2024.
//

import UIKit
import FirebaseAuth
///görseller ve animasyonlar için kullanıyoruz
import JGProgressHUD

final class ConversationViewController: UIViewController{
    
    private let spinner = JGProgressHUD(style: JGProgressHUDStyle.dark)
    private var conversations = [Conversation]()
    
    private let tableView : UITableView = {
        let table = UITableView()
        //eğer conversation yoksa table view un gözükmesini istwmiyoruz onun yerine no conv yazısı gözüksün
        table.isHidden = true
        table.register(ConversationTableViewCell.self, forCellReuseIdentifier: ConversationTableViewCell.Identifier)

        return table
    }()
    
    private let noConvoLabel : UILabel = {
        let label = UILabel()
        label.text="No Conversations!"
        label.textAlignment = .center
        label.textColor = .gray
        label.font = .systemFont(ofSize: 21, weight: .medium)
        return label
    }()
    
    private var loginObserver : NSObjectProtocol?
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        navigationController?.navigationBar.isHidden=false
        //alttaki profile ve chat butonları gözükmesi için
        
        navigationItem.rightBarButtonItem = UIBarButtonItem(barButtonSystemItem: .compose,
                                                            target: self,
                                                            action: #selector(didTapComposeButton))
        tableView.delegate=self
        tableView.dataSource=self
        
        view.addSubview(tableView)
        view.addSubview(noConvoLabel)
        setUpTableView()
       // fetchConversations()
        startListeningForConversation()
        //extension da oluşturdupumuz ismi verdik .didnot
        loginObserver = NotificationCenter.default.addObserver(forName: Notification.Name.didLogInNotification,object:nil,
                                                               queue: .main, using: { [weak self] _ in
            guard let strongSelf = self else{return}
            strongSelf.startListeningForConversation()
            
        })
        
        
    }
    
    private func startListeningForConversation(){
        guard let email = UserDefaults.standard.value(forKey: "email") as? String else {
            return
        }
        if let observer = loginObserver{
            NotificationCenter.default.removeObserver(observer)
        }
        print("starting convo fetch...")
        let safeEmail = DatabaseManager.safeEmail(emailAdress: email)
        DatabaseManager.shared.getAllConversations(for:safeEmail) { [weak self] result in
            switch result{
            case .success(let conversation) :
                print("successfully got convo models")
                guard !conversation.isEmpty else{
                    self?.tableView.isHidden=true
                    self?.noConvoLabel.isHidden = false

                    return
                }
                self?.noConvoLabel.isHidden = true
                self?.tableView.isHidden=false
                self?.conversations = conversation
                
                DispatchQueue.main.async {
                    self?.tableView.reloadData()
                }
                
            case .failure( let error) :
                print("hata burdaaaaa")
                print("failed to get convos : \(error)")
            }
        }
    }
    
    
    @objc func didTapComposeButton(){
        let vc = NewConversationViewController()
        //newconvoVC deki önceki konusma sonuclarına eisitk,var mı yok mu dieye
        vc.completion = { [weak self ] result in
            //["safe_email": "beyza-gmal-com","name":"beyza tastan"]
            
            //eğer zaten sohbetimz varsa olan sohbeti aç,yoksa yeni oluştur
            guard let strongSelf = self else{return}
            
            let currentConvos = strongSelf.conversations
            if let targetConvo = currentConvos.first(where: {
                $0.otherUserEmail == DatabaseManager.safeEmail(emailAdress: result.email)
                
            })
                
            {
                let vc=ChatViewController(with:targetConvo.otherUserEmail, id: targetConvo.id)
                vc.isNewConversation=false
                vc.title = targetConvo.name
                //title ı küçük gösteriyo
                vc.navigationItem.largeTitleDisplayMode = .never
                strongSelf.navigationController?.pushViewController(vc, animated: true)
                
                
                //eger önceden bir konuşmamız yoksa yeni yarat
            }  else {
                   
                    strongSelf.createNewConversation(result: result)
                }
            
        
        }
        let navVc=UINavigationController(rootViewController: vc)
        present(navVc,animated: true)
    }
    
    
    private func createNewConversation(result:SearchResults){
     //  let name = result["name"] , let email = result["safe_email"] else{
           //eğer kullanıcı yoksa result içinde
        let name = result.name
        let email = result.email
        
        DatabaseManager.shared.conversationExists(with: email) { [weak self] result in
            guard let strongSelf = self else{
                return
            }
            switch result{
            case .success(let convoId):
                let vc=ChatViewController(with:email, id: convoId)
                vc.isNewConversation=false
                vc.title = name
                //title ı küçük gösteriyo
                vc.navigationItem.largeTitleDisplayMode = .never
                strongSelf.navigationController?.pushViewController(vc, animated: true)
            case .failure(_):
                let vc=ChatViewController(with:email, id: nil)
                vc.isNewConversation=true
                vc.title = name
                //title ı küçük gösteriyo
                vc.navigationItem.largeTitleDisplayMode = .never
                strongSelf.navigationController?.pushViewController(vc, animated: true)
            }
        }
           }
    
    
    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        //tüm ekranın table view olmasını sağlıyor
        tableView.frame=view.bounds
        noConvoLabel.frame = CGRect(x: 10, y: (view.height-100)/2, width: view.width-20, height: 100)
    }
    
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        
        validateAuth()
        
    }
    private func validateAuth(){
        
        //kullanıcı oturum açmadıysa ya da oturumu kapatılmışsa login sayfasına git
        if FirebaseAuth.Auth.auth().currentUser == nil {
            let vc=LoginViewController()
            let nav=UINavigationController(rootViewController: vc)
            //eğer bunu yazmazsak sayfa pop in şekilde gelir ve kullanıcı onu aşağı sürükleyip geçebilir
            nav.modalPresentationStyle = .fullScreen
            present(nav,animated: true)
        }
    }
    
    private func setUpTableView(){
        tableView.delegate=self
        tableView.dataSource=self
    }
    
}
extension ConversationViewController : UITableViewDelegate, UITableViewDataSource {
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return conversations.count
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let model = conversations[indexPath.row]
        let cell = tableView.dequeueReusableCell(withIdentifier: ConversationTableViewCell.Identifier, for: indexPath) as! ConversationTableViewCell
        cell.configure(with: model)
        return cell
    }
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        //seçilen yeri unhighlight ediyo
        tableView.deselectRow(at: indexPath, animated: true)
        let model = conversations[indexPath.row]
        openConversations(model)
        }
    func openConversations(_ model : Conversation){
        
        let vc=ChatViewController(with: model.otherUserEmail , id: model.id)
        vc.title = model.name
        //title ı küçük gösteriyo
        vc.navigationItem.largeTitleDisplayMode = .never
        navigationController?.pushViewController(vc, animated: true)
   
    }
    
    func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        return 120
    }
    
    
    
    //mesajlaır silebilmemiz için
    func tableView(_ tableView: UITableView, editingStyleForRowAt indexPath: IndexPath) -> UITableViewCell.EditingStyle {
        return .delete
    }
    
    //silme işlemi burda yapılacak
    func tableView(_ tableView: UITableView,commit editingStyle:UITableViewCell.EditingStyle,forRowAt indexPath :IndexPath){
        if editingStyle == .delete{
            //begin delete
            let conversationId = conversations[indexPath.row].id
            tableView.beginUpdates()
            self.conversations.remove(at: indexPath.row)
            tableView.deleteRows(at: [indexPath], with: UITableView.RowAnimation.left)

            DatabaseManager.shared.deleteConversation(conversationId:conversationId ) {success in
                if !success{
                    print("failed to delete")
                    }
                }
          
            tableView.endUpdates()
           
        }
    }
    
}

