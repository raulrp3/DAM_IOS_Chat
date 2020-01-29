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

        AppData.active = false
        
        navigationItem.hidesBackButton = true
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
        
        self.performSegue(withIdentifier: "segue", sender: nil)
    }
    
    override func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        return 60
    }
    
    override func tableView(_ tableView: UITableView, trailingSwipeActionsConfigurationForRowAt indexPath: IndexPath) -> UISwipeActionsConfiguration? {
        let name = AppData.contacts[indexPath.row].name
        
        let delete = UIContextualAction(style: .destructive, title: "Limpiar"){ (_, _, boolValue) in
            boolValue(true)
            
            let alertController = UIAlertController(title: "Limpiar conversación", message: "¿Está seguro que desea limpiar esta conversación?", preferredStyle: .alert)
            
            let accept = UIAlertAction(title: "Aceptar", style: .default, handler: { alert in
                self.removeChat(name)
            })
            
            let cancel = UIAlertAction(title: "Cancelar", style: .default, handler: nil)
            
            alertController.addAction(cancel)
            alertController.addAction(accept)
            
            self.present(alertController, animated: true, completion: nil)
        }
        
        let configuration = UISwipeActionsConfiguration(actions: [delete])
        configuration.performsFirstActionWithFullSwipe = false
        
        return configuration
    }
    
    func removeChat(_ name: String){
        AppData.chats[name]?.removeAll()
        
        UserDefaults.standard.set("", forKey: "titles\(name)")
        UserDefaults.standard.set("", forKey: "bodys\(name)")
    }
}

struct AppData {
    static let contacts: [(name: String, token: String)] = [(name: "Fran", token: "e3480807cafcf6eb6286adf22054d26a708add7f832c8d95745892b60d217a17"), (name: "Raul", token: "f81a5415e5cbbf525b2163039ca6edc711f20c08eb7a48deb93350d932b11195")]
    static var chats: [String: [(title: String, body: String)]] = ["Fran": [], "Raul": []]
    static var token: String = ""
    static var name: String = ""
    static let url: String = "https://qastusoft.es/test/estech/"
    static var active: Bool = false
}

