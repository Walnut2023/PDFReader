//
//  APTabBarController.swift
//  APReader
//
//  Created by Tango on 2020/8/28.
//  Copyright © 2020 Tangorios. All rights reserved.
//

import UIKit

class APTabBarController: UITabBarController {

    override func viewDidLoad() {
        super.viewDidLoad()
        delegate = self
    }

}

extension APTabBarController: UITabBarControllerDelegate {
    func tabBarController(_ tabBarController: UITabBarController, shouldSelect viewController: UIViewController) -> Bool {
        let tabTitle: String = viewController.tabBarItem.title ?? ""
        if tabTitle.elementsEqual("OneDrive") {
            APAuthManager.instance.getTokenSilently { (token: String?, error: Error?) in
                DispatchQueue.main.async {
                    let storyBoard = UIStoryboard(name: "Main", bundle: nil)
                    guard let _ = token, error == nil else {
                        // If there is no token or if there's an error,
                        // no user is signed in, so stay here
                        print("user status: not sign in")
                        let vc = storyBoard.instantiateViewController(identifier: "SignInVC")
                        self.present(vc, animated: true)
                        return
                    }
                }
            }
        }
        return true
    }
}
