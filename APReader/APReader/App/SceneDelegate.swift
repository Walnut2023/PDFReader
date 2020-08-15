//
//  SceneDelegate.swift
//  APReader
//
//  Created by Tangos on 2020/7/25.
//  Copyright © 2020 Tangorios. All rights reserved.
//

import UIKit

class SceneDelegate: UIResponder, UIWindowSceneDelegate {

    var window: UIWindow?


    func scene(_ scene: UIScene, willConnectTo session: UISceneSession, options connectionOptions: UIScene.ConnectionOptions) {
        // Use this method to optionally configure and attach the UIWindow `window` to the provided UIWindowScene `scene`.
        // If using a storyboard, the `window` property will automatically be initialized and attached to the scene.
        // This delegate does not imply the connecting scene or session are new (see `application:configurationForConnectingSceneSession` instead).
        guard let _ = (scene as? UIWindowScene) else { return }
        if let windowScene = scene as? UIWindowScene {
            window = UIWindow(windowScene: windowScene)
            let storyBoard = UIStoryboard(name: "Main", bundle: nil)
            
            // workaround for svprogresshud
            let appDelegate = UIApplication.shared.delegate as! AppDelegate
            appDelegate.window = window
            
            APAuthManager.instance.getTokenSilently { (token: String?, error: Error?) in
                DispatchQueue.main.async {
                    guard let _ = token, error == nil else {
                        // If there is no token or if there's an error,
                        // no user is signed in, so stay here
                        print("user status: not sign in")
                        let vc = storyBoard.instantiateViewController(identifier: "SignInVC")
                        self.window?.rootViewController = vc
                        self.window?.makeKeyAndVisible()
                        return
                    }
                    let vc = storyBoard.instantiateViewController(identifier: "TabbarVC")
                    self.window?.rootViewController = vc
                    self.window?.makeKeyAndVisible()
                }
            }

        }
    }

    func sceneDidDisconnect(_ scene: UIScene) {
        // Called as the scene is being released by the system.
        // This occurs shortly after the scene enters the background, or when its session is discarded.
        // Release any resources associated with this scene that can be re-created the next time the scene connects.
        // The scene may re-connect later, as its session was not neccessarily discarded (see `application:didDiscardSceneSessions` instead).
    }

    func sceneDidBecomeActive(_ scene: UIScene) {
        // Called when the scene has moved from an inactive state to an active state.
        // Use this method to restart any tasks that were paused (or not yet started) when the scene was inactive.
    }

    func sceneWillResignActive(_ scene: UIScene) {
        // Called when the scene will move from an active state to an inactive state.
        // This may occur due to temporary interruptions (ex. an incoming phone call).
    }

    func sceneWillEnterForeground(_ scene: UIScene) {
        // Called as the scene transitions from the background to the foreground.
        // Use this method to undo the changes made on entering the background.
    }

    func sceneDidEnterBackground(_ scene: UIScene) {
        // Called as the scene transitions from the foreground to the background.
        // Use this method to save data, release shared resources, and store enough scene-specific state information
        // to restore the scene back to its current state.
    }

    // MARK: - Helper
    func userSignedIn() -> Bool {
        var userSignedIn = true
        APAuthManager.instance.getTokenSilently {
            (token: String?, error: Error?) in
            DispatchQueue.main.async {
                guard let _ = token, error == nil else {
                    // If there is no token or if there's an error,
                    // no user is signed in, so stay here
                    userSignedIn = false
                    print("user status: not sign in")
                    return
                }
                print("user status: signed in")
            }
        }
        print("will return user status")
        return userSignedIn
    }

}

