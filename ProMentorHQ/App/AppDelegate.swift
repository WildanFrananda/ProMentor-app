//
//  AppDelegate.swift
//  ProMentorHQ
//
//  Created by Wildan Frananda on 28/10/25.
//

import UIKit
import UserNotifications

class AppDelegate: NSObject, UIApplicationDelegate, UNUserNotificationCenterDelegate {
    var appContainer: AppContainer?
    
    private var logger: LoggerProtocol {
        return appContainer?.logger ?? ConsoleLogger()
    }
    
    func registerForPushNotification() -> Void {
        logger.info("AppDelegate: Request push notification permission...")
        
        UNUserNotificationCenter.current().delegate = self
        UNUserNotificationCenter.current().requestAuthorization(
            options: [.alert, .sound, .badge]
        ) { [weak self] granted, error in
            guard let self = self else { return }
            
            if let error = error {
                self.logger.error("AppDelegate: Failed request APNs permission", error: error)
                return
            }
            
            guard granted else {
                self.logger.warning("AppDelegate: APNs permission denied by user.")
                return
            }
            
            self.logger.info("AppDelegate: APNs permission granted. Registering with APNs....")
            
            DispatchQueue.main.async {
                UIApplication.shared.registerForRemoteNotifications()
            }
        }
    }
    
    func application(
        _ application: UIApplication,
        didRegisterForRemoteNotificationsWithDeviceToken deviceToken: Data
    ) -> Void {
        let tokenString = deviceToken.map { String(format: "%02.2hhx", $0) }.joined()
        logger.info("AppDelegate: Received device token APNs: \(tokenString)")
        
        Task {
            do {
                try await appContainer?.authRepository.registerDeviceToken(tokenString)
                logger.info("AppDelegate: Device token submitted to backend.")
            } catch {
                logger.error("AppDelegate: Could not send device token to backend", error: error)
            }
        }
    }
    
    func application(
        _ application: UIApplication,
        didFailToRegisterForRemoteNotificationsWithError error: Error
    ) {
        logger.error("AppDelegate: Failed registering APNs", error: error)
    }
    
    func userNotificationCenter(
        _ center: UNUserNotificationCenter,
        willPresent notification: UNNotification,
        withCompletionHandler completionHandler: @escaping (UNNotificationPresentationOptions) -> Void
    ) -> Void {
        logger.info("AppDelegate: Receiving foreground notifications.")
        completionHandler([.banner, .sound, .list])
    }
    
    func userNotificationCenter(
        _ center: UNUserNotificationCenter,
        didReceive response: UNNotificationResponse,
        withCompletionHandler completionHandler: @escaping () -> Void
    ) {
        logger.info("AppDelegate: User tapping notification.")
        // TODO: Handle deep link di sini jika ada.
        // Misalnya: baca `userInfo` dan update `appState` untuk navigasi.
        
        completionHandler()
    }
}
