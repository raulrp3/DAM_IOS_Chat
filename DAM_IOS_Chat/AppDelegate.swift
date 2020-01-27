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

        AppData.chats[title]?.append((title: title, body: body))
        
        DispatchQueue.main.async {
            let trigger = UNTimeIntervalNotificationTrigger(timeInterval: 0.0, repeats: false)

            let content = UNMutableNotificationContent()
            content.title = "Notificación de \(title)"
            content.subtitle = ""
            content.body = "\(title): \(body)"
            content.sound = .default

            let request = UNNotificationRequest(identifier: "NOTIFICACION", content: content, trigger: trigger)

            UNUserNotificationCenter.current().removeAllDeliveredNotifications()
            UNUserNotificationCenter.current().add(request){ error in
                if let error = error{
                    print("¡Error: \(error)!")
                }
            }
        }
    }
    
    func userNotificationCenter(_ center: UNUserNotificationCenter, willPresent notification: UNNotification, withCompletionHandler completionHandler: @escaping (UNNotificationPresentationOptions) -> Void){
        completionHandler([.alert, .sound])
        
        let title: String = notification.request.content.title
        let body: String = notification.request.content.body
        
        AppData.chats[title]?.append((title: title, body: body))
        
        DispatchQueue.main.async{
            let viewController: UINavigationController = (UIApplication.shared.windows.filter{$0.isKeyWindow}.first)!.rootViewController as! UINavigationController
            
            if title == AppData.name{
                let view: ChatController = viewController.visibleViewController as! ChatController
                view.mTableview.reloadData()
            }
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
                    
                    AppData.chats[title]?.append((title: "Raul", body: body))
                    
                    let urlString: String = "\(AppData.url)\(AppData.name)/index.php?token=\(token)&title=Raul&body=\(body.replacingOccurrences(of: " ", with: "%20"))"
                    
                    guard let url = URL(string: urlString) else { return }
                    
                    URLSession.shared.dataTask(with: url){ (data, response, error) in
                        if error != nil{
                            print(error!.localizedDescription)
                        }
                    }.resume()
                break
                default:
                    AppData.name = aps["alert"]?["title"] as! String
                    AppData.token = self.searchDeviceToken(AppData.name)
                    
                    let body: String = aps["alert"]?["body"] as! String
                    
                    AppData.chats[AppData.name]?.append((title: AppData.name, body: body))
                    
                    DispatchQueue.main.async{
                        let storyboard = UIStoryboard(name: "Main", bundle: nil)
                        let chatView = storyboard.instantiateViewController(identifier: "chatView")
                        
                        chatView.modalPresentationStyle = UIModalPresentationStyle.fullScreen
                        
                        (UIApplication.shared.windows.filter{$0.isKeyWindow}.first)?.rootViewController?.present(chatView, animated: true, completion: nil)
                    }
                break
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
}

