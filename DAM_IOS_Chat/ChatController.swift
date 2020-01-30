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
    @IBOutlet weak var mButton: UIButton!
    
    override func viewDidLoad() {
        self.navigationItem.title = "Conversación con \(AppData.name)"
        
        self.hideKeyboardWhenTappedAraound()
        
        AppData.active = true
        
        self.loadMessages(AppData.name)
        
        mButton.layer.cornerRadius = 5
        
        self.registerForKeyboardNotifications()
    }
    
    func numberOfSections(in tableView: UITableView) -> Int {
        return 1
    }
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return (AppData.chats[AppData.name]?.count)!
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "mCellChat") as! CellChat
        
        let title: String = AppData.chats[AppData.name]![indexPath.row].title
        let body: String = AppData.chats[AppData.name]![indexPath.row].body
        
        cell.message.text = "\(body)"
        
        if title == "Raul"{
            cell.message.textAlignment = .right
            cell.backgroundColor = UIColor(red: 195/255, green: 207/255, blue: 230/255, alpha: 1.0)
        }else{
            cell.message.textAlignment = .left
            cell.backgroundColor = UIColor(red: 189/255, green: 210/255, blue: 252/255, alpha: 1.0)
        }
        
        return cell;
    }
    
    func tableView(_ tableView: UITableView, willDisplay cell: UITableViewCell, forRowAt indexPath: IndexPath) {
        let verticalPadding: CGFloat = 5
        let horizontalPadding: CGFloat = 20

        let maskLayer = CALayer()
        maskLayer.cornerRadius = 10
        maskLayer.backgroundColor = UIColor.black.cgColor
        maskLayer.frame = CGRect(x: cell.bounds.origin.x, y: cell.bounds.origin.y, width: cell.bounds.width, height: cell.bounds.height).insetBy(dx: horizontalPadding/2, dy: verticalPadding/2)
        cell.layer.mask = maskLayer
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
    
    func registerForKeyboardNotifications(){
        NotificationCenter.default.addObserver(self, selector: #selector(self.keyboardWillShow(notification:)), name: UIResponder.keyboardDidShowNotification, object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(self.keyboardWillHide(notification:)), name: UIResponder.keyboardDidHideNotification, object: nil)
    }
    
    @objc func keyboardWillShow(notification: NSNotification){
        if let keyboardFrame: NSValue = notification.userInfo?[UIResponder.keyboardFrameEndUserInfoKey] as? NSValue{
            if self.view.frame.origin.y == 0{
                UIView.animate(withDuration: 0.5, delay: 0.0, options: [], animations: { [weak self] in
                    self?.view.frame.origin.y -= keyboardFrame.cgRectValue.height
                }, completion: nil)
            }
        }
    }
    
    @objc func keyboardWillHide(notification: NSNotification){
        if let keyboardFrame: NSValue = notification.userInfo?[UIResponder.keyboardFrameEndUserInfoKey] as? NSValue{
            if self.view.frame.origin.y != 0{
                UIView.animate(withDuration: 0.5, delay: 0.0, options: [], animations: { [weak self] in
                    self?.view.frame.origin.y += keyboardFrame.cgRectValue.height
                }, completion: nil)
            }
        }
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
