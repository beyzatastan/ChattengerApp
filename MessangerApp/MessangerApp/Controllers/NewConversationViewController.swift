//
//  NewConversationViewController.swift
//  MessangerApp
//
//  Created by beyza nur on 14.02.2024.
//

import UIKit
import JGProgressHUD

class NewConversationViewController: UIViewController {
    
    
    //bi closure oluşturmamız gerekiyor,eğer varsa zaten sohbet gecmisi eni sohbet oluşturmasın terrardan ,var olan sohbeti açsın diye
    public var completion : ((SearchResults) -> (Void))?
    
    private let spinner = JGProgressHUD(style: .dark)
    
    //userobjelerini içinde barındırıacak array oluşturucaz
    private var users = [[String:String]]()
    private var hasFetched = false
    
    private var results = [SearchResults]()
    
    private let searchBar : UISearchBar = {
        let searchBar=UISearchBar()
        searchBar.placeholder = "Search for Users..."
        return searchBar
    }()
    
    
    private let tableView : UITableView = {
       let table = UITableView()
        table.isHidden=true
        table.register(NewConversationCell.self, forCellReuseIdentifier: NewConversationCell.Identifier)
        return table
    }()
    
    private let noResultsLabel :UILabel = {
       let label = UILabel()
        label.isHidden = true
        label.text="No Results"
        label.textAlignment = .center
        label.textColor = .green
        label.font = .systemFont(ofSize: 21, weight: .medium)
        return label
        
    }()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        view.addSubview(noResultsLabel)
        view.addSubview(tableView)
        
        tableView.delegate=self
        tableView.dataSource=self
        
        view.backgroundColor = .white
        searchBar.delegate = self
        //searchbar ı navigation ın içine atıyo ki framelerle ugrasmayalım
        navigationController?.navigationBar.topItem?.titleView = searchBar
        navigationItem.rightBarButtonItem = UIBarButtonItem(title: "Cancel",
                                                            style: .done,
                                                            target: self,
                                                            action: #selector(
                                                                dismissSelf))
        
        //aramaya basılmadan basılmış gibi davranıyor ki yeni sohebt tusuna basılınca direkt keybord acılsın
        searchBar.becomeFirstResponder()
        
    }
    
    @objc private func dismissSelf(){
        dismiss(animated: true, completion: nil)
    }
    
    //yazmazsak ekrandakierin framleri olamdığı için görünmez
    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        tableView.frame=view.bounds
        noResultsLabel.frame=CGRect(x: view.width/4, y: (view.height-200)/2, width: view.width/2, height: 200)
    }
    


}

extension   NewConversationViewController : UITableViewDelegate,UITableViewDataSource{
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return results.count
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let model = results[indexPath.row]
        let cell=tableView.dequeueReusableCell(withIdentifier: NewConversationCell.Identifier, for: indexPath) as! NewConversationCell
        cell.configure(with: model)
        return cell
    }
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        tableView.deselectRow(at: indexPath, animated: true)
        //start conversation
        let targetUserData = results[indexPath.row]
        dismiss(animated: true, completion:{ [weak self] in
            self?.completion?(targetUserData)
        })
    
    }
    func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        return 90
    }
    
}


extension NewConversationViewController:UISearchBarDelegate{
    func searchBarSearchButtonClicked(_ searchBar: UISearchBar) {
        //space e basıldığındaki boşluğu yok et dedik
        guard let text  = searchBar.text ,!text.replacingOccurrences(of: " ", with: "").isEmpty else {return}
        
        searchBar.resignFirstResponder()
        
        results.removeAll()
        spinner.show(in: view)
        self.searchUsers(query: text)
    }
    
    //Tableview u güncellemek için
    func searchUsers(query:String){
        //arrayin içinde firebase results var mı kontrol et
        if hasFetched{
            //varsa filtrele aramayı
            filterUsers(with: query)
            
        }
        else {
            //yoksa önce fetch et sonra filtrele
            DatabaseManager.shared.getAllUsers { [weak self] results in
                switch results {
                case .success(let usersCollection):
                    self?.hasFetched = true
                    self?.users = usersCollection
                    self?.filterUsers(with: query)
                case .failure(let error):
                    print("failed to get users: \(error)")
                }
            }
        }
        
    }
    
    func filterUsers(with term:String){
        //update uı :either show results or no results label
        
        guard let currentUserEmail = UserDefaults.standard.value(forKey: "email") as? String ,hasFetched else {
            return
        }
        let safeEmail = DatabaseManager.safeEmail(emailAdress: currentUserEmail)
        self.spinner.dismiss()
        let results : [SearchResults] = self.users.filter({
            guard let email = $0["email"] , email != safeEmail else{
                 
                return false
            }
            guard let name = $0["name"]?.lowercased() else{
                return false
            }
            //kelimenin içinde yazdığımız kombinasyon varsa direkt getirir
            return name.hasPrefix(term.lowercased())
        }).compactMap ({
            guard let email = $0["email"],let name = $0["name"] else{
                return nil
            }
            return SearchResults(name: name, email: email)
        })
        self.results = results
        updateUI()
    }
    
    func updateUI(){
        if results.isEmpty{
            self.noResultsLabel.isHidden=false
            self.tableView.isHidden=true
        }
        else{
            self.noResultsLabel.isHidden=true
            self.tableView.isHidden=false
            self.tableView.reloadData()
        }
    }
    
    
}

struct SearchResults {
    let name :String
    let email : String
}
