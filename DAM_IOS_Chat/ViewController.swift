//
//  ViewController.swift
//  DAM_IOS_Chat
//
//  Created by raul.ramirez on 22/01/2020.
//  Copyright © 2020 Raul Ramirez. All rights reserved.
//

import UIKit

class ViewController: UITableViewController {

    override func viewDidLoad() {
        super.viewDidLoad()
        // Do any additional setup after loading the view.
        AppData.name = ""
        AppData.token = ""
    }

    override func numberOfSections(in tableView: UITableView) -> Int {
        return 1
    }
    
    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return AppData.contacts.count
    }
    
    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "mCell") as! Cell
        
        cell.name.text = AppData.contacts[indexPath.row].name
        
        return cell;
    }
    
    override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        AppData.token = AppData.contacts[indexPath.row].token
        AppData.name = AppData.contacts[indexPath.row].name
        
        DispatchQueue.main.async{
            let storyboard = UIStoryboard(name: "Main", bundle: nil)
            let chatView = storyboard.instantiateViewController(identifier: "chatView")
            
            chatView.modalPresentationStyle = UIModalPresentationStyle.fullScreen
            
            self.present(chatView, animated: true, completion: nil)
        }
    }
    
    override func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        return 60
    }
}

struct AppData {
    static let contacts: [(name: String, token: String)] = [(name: "Fran", token: "e3480807cafcf6eb6286adf22054d26a708add7f832c8d95745892b60d217a17"), (name: "Raul", token: "f81a5415e5cbbf525b2163039ca6edc711f20c08eb7a48deb93350d932b11195")]
    static var chats: [String: [(title: String, body: String)]] = ["Fran": [(title: "Fran", body: "Hola!")], "Raul": []]
    static var token: String = ""
    static var name: String = ""
    static let url: String = "https://qastusoft.es/test/estech/"
}

