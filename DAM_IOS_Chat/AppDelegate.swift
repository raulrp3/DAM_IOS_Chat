//
//  AppDelegate.swift
//  DAM_IOS_Chat
//
//  Created by raul.ramirez on 22/01/2020.
//  Copyright © 2020 Raul Ramirez. All rights reserved.
//

import UIKit
import UserNotifications

@UIApplicationMain
class AppDelegate: UIResponder, UIApplicationDelegate, UNUserNotificationCenterDelegate {

    func application(_ application: UIApplication, didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?) -> Bool {
        // Override point for customization after application launch.
        self.registerForPushNotifications()
        UNUserNotificationCenter.current().delegate = self
        
        return true
    }
    
    func registerForPushNotifications(){
        UNUserNotificationCenter.current().requestAuthorization(options: [.alert, .sound, .badge]){ [weak self] granted, error in
            guard granted else { return }
            
            let sleepAction = UNNotificationAction(identifier: "SLEEP_ACTION", title: "No molestar", options: [.foreground])
            
            let category = UNNotificationCategory(identifier: "sleep", actions: [sleepAction], intentIdentifiers: [], hiddenPreviewsBodyPlaceholder: "", options: .customDismissAction)
            
            let notificationCenter = UNUserNotificationCenter.current()
            notificationCenter.setNotificationCategories([category])
            
            self?.getNotificationSettings()
        }
    }
    
    func getNotificationSettings(){
        UNUserNotificationCenter.current().getNotificationSettings{ settings in
            guard settings.authorizationStatus == .authorized else { return }
            DispatchQueue.main.async {
                UIApplication.shared.registerForRemoteNotifications()
            }
        }
    }
    
    func application(_ application: UIApplication, didRegisterForRemoteNotificationsWithDeviceToken deviceToken: Data) {
        let tokenParts = deviceToken.map{ data in String(format: "%02.2hhx", data)}
        let token = tokenParts.joined()
        
        print("Device token: \(token)")
    }
    
    func application(_ application: UIApplication, didFailToRegisterForRemoteNotificationsWithError error: Error) {
        print("Failed to register: \(error)")
    }

    // MARK: UISceneSession Lifecycle

    func application(_ application: UIApplication, configurationForConnecting connectingSceneSession: UISceneSession, options: UIScene.ConnectionOptions) -> UISceneConfiguration {
        // Called when a new scene session is being created.
        // Use this method to select a configuration to create the new scene with.
        return UISceneConfiguration(name: "Default Configuration", sessionRole: connectingSceneSession.role)
    }

    func application(_ application: UIApplication, didDiscardSceneSessions sceneSessions: Set<UISceneSession>) {
        // Called when the user discards a scene session.
        // If any sessions were discarded while the application was not running, this will be called shortly after application:didFinishLaunchingWithOptions.
        // Use this method to release any resources that were specific to the discarded scenes, as they will not return.
    }

    func application(_ application: UIApplication, didReceiveRemoteNotification userInfo: [AnyHashable : Any], fetchCompletionHandler completionHandler: @escaping (UIBackgroundFetchResult) -> Void) {
        guard let aps = userInfo["aps"] as? [String: AnyObject] else {
            completionHandler(.failed)
            return
        }
        
        let title = aps["alert"]?["title"] as! String
        let body = aps["alert"]?["body"] as! String
        
        self.loadMessages(title)

        AppData.chats[title]?.append((title: title, body: body))
        
        self.saveMessages(title)
        
        DispatchQueue.main.async{
            let viewController: UINavigationController = (UIApplication.shared.windows.filter{$0.isKeyWindow}.first)!.rootViewController as! UINavigationController
            
            if AppData.active{
                let view: ChatController = viewController.visibleViewController as! ChatController
                view.mTableview.reloadData()
            }
        }
        
        completionHandler(.noData)
    }
    
    func userNotificationCenter(_ center: UNUserNotificationCenter, willPresent notification: UNNotification, withCompletionHandler completionHandler: @escaping (UNNotificationPresentationOptions) -> Void){
        if notification.request.content.title != AppData.name{
            completionHandler([.alert, .sound])
        }else{
            completionHandler([])
        }
    }
    
    func userNotificationCenter(_ center: UNUserNotificationCenter, didReceive response: UNNotificationResponse, withCompletionHandler completionHandler: @escaping () -> Void){
        let userInfo = response.notification.request.content.userInfo
        
        if let aps = userInfo["aps"] as? [String: AnyObject]{
            switch response.actionIdentifier{
                case "SLEEP_ACTION":
                    let title: String = aps["alert"]?["title"] as! String
                    let token: String = self.searchDeviceToken(title)
                    
                    let body: String = "Estoy ocupado, por favor no molestar."
                    
                    self.loadMessages(title)
                    
                    AppData.chats[title]?.append((title: "Raul", body: body))
                    
                    self.saveMessages(title)
                    
                    let urlString: String = "\(AppData.url)\(title)/index.php?token=\(token)&title=Raul&body=\(body.replacingOccurrences(of: " ", with: "%20"))"
                    
                    guard let url = URL(string: urlString) else { return }
                    
                    URLSession.shared.dataTask(with: url){ (data, response, error) in
                        if error != nil{
                            print(error!.localizedDescription)
                        }
                    }.resume()
                    break;
                default:
                    AppData.name = aps["alert"]?["title"] as! String
                    AppData.token = self.searchDeviceToken(AppData.name)
                    
                    DispatchQueue.main.async{
                        let storyboard = UIStoryboard(name: "Main", bundle: nil)
                        let chatView = storyboard.instantiateViewController(identifier: "chatView") as! ChatController
                            
                        let window = (UIApplication.shared.windows.filter{$0.isKeyWindow}.first?.rootViewController) as! UINavigationController

                        window.pushViewController(chatView, animated: true)
                    }
                    break;
            }
        }
        
        completionHandler()
    }
    
    func searchDeviceToken(_ title: String) -> String{
        var token: String = ""
        
        for message in AppData.contacts{
            if message.0 == title{
                token = message.1
            }
        }
        
        return token
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

