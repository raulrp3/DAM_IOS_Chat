//
//  ChatController.swift
//  DAM_IOS_Chat
//
//  Created by raul.ramirez on 23/01/2020.
//  Copyright © 2020 Raul Ramirez. All rights reserved.
//

import UIKit

class ChatController: UIViewController, UITableViewDelegate, UITableViewDataSource {
    @IBOutlet weak var message: UITextField!
    @IBOutlet weak var mTableview: UITableView!
    
    override func viewDidLoad() {
        self.navigationItem.title = "Conversación con \(AppData.name)"
        
        self.hideKeyboardWhenTappedAraound()
        
        AppData.active = true
        
        self.loadMessages(AppData.name)
    }
    
    func numberOfSections(in tableView: UITableView) -> Int {
        return 1
    }
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return (AppData.chats[AppData.name]?.count)!
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "mCellChat") as! CellChat
        
        cell.message.text = "\(AppData.chats[AppData.name]![indexPath.row].title): \(AppData.chats[AppData.name]![indexPath.row].body)"
        
        return cell;
    }
    
    func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        return 60
    }
    
    @IBAction func sendAction(_ sender: Any) {
        AppData.chats[AppData.name]?.append((title: "Raul", body: self.message.text!))
        
        self.saveMessages(AppData.name)
        
        self.mTableview.reloadData()
        
        let urlString: String = "\(AppData.url)\(AppData.name)/index.php?token=\(AppData.token)&title=Raul&body=\(message.text!.replacingOccurrences(of: " ", with: "%20"))"
        
        guard let url = URL(string: urlString) else { return }
        
        URLSession.shared.dataTask(with: url){ (data, response, error) in
            if error != nil{
                print(error!.localizedDescription)
            }
        }.resume()
        
        self.message.text = ""
    }
    
    
    @IBAction func backAction(_ sender: Any) {
        AppData.active = false
        
        DispatchQueue.main.async{
            let storyboard = UIStoryboard(name: "Main", bundle: nil)
            let contactsView = storyboard.instantiateViewController(identifier: "contactsView")
            
            contactsView.modalPresentationStyle = UIModalPresentationStyle.fullScreen
            
            self.present(contactsView, animated: true, completion: nil)
        }
    }
    
    override func viewDidDisappear(_ animated: Bool) {
        self.saveMessages(AppData.name)
        
        AppData.name = ""
        AppData.token = ""
    }
    
    func loadMessages(_ name: String){
        if UserDefaults.standard.array(forKey: "titles\(name)") != nil && UserDefaults.standard.array(forKey: "bodys\(name)") != nil{
            let titles: [String] = UserDefaults.standard.array(forKey: "titles\(name)") as! [String]
            let bodys: [String] = UserDefaults.standard.array(forKey: "bodys\(name)") as! [String]
            
            AppData.chats[name]?.removeAll()
            
            for (index, title) in titles.enumerated(){
                AppData.chats[name]?.append((title: title, body: bodys[index]))
            }
        }
    }
    
    func saveMessages(_ name: String){
        var titles: [String] = []
        var bodys: [String] = []
        
        for data in (AppData.chats[name])!{
            titles.append(data.title)
            bodys.append(data.body)
        }
        
        UserDefaults.standard.set(titles, forKey: "titles\(name)")
        UserDefaults.standard.set(bodys, forKey: "bodys\(name)")
    }
}

extension UIViewController{
    func hideKeyboardWhenTappedAraound(){
        let tap: UITapGestureRecognizer = UITapGestureRecognizer(target: self, action: #selector(UIViewController.dismissKeyboard))
        tap.cancelsTouchesInView = false
        view.addGestureRecognizer(tap)
    }
    
    @objc func dismissKeyboard(){
        view.endEditing(true)
    }
}
