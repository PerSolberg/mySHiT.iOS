//
//  SettingsViewController.swift
//  mySHiT
//
//  Created by Per Solberg on 2015-10-09.
//  Copyright © 2015 Per Solberg. All rights reserved.
//

import UIKit

class LogonViewController: UIViewController, UITextFieldDelegate {

    // MARK: Properties
    @IBOutlet weak var userNameTextField: UITextField!
    @IBOutlet weak var passwordTextField: UITextField!
    @IBOutlet weak var logonButton: UIButton!
    
    var activeField: UITextField?
    
    // MARK: Callbacks
    @IBOutlet weak var scrollView: UIScrollView!

    override func viewDidLoad() {
        super.viewDidLoad()

        // Fix localisation for UITextView
        self.view.processSubviews(true, processChildrenFirst: true, action: { (view:UIView, level:Int) in
            if view.isKind(of: UITextView.self) && view.restorationIdentifier != nil {
                let textView = view as! UITextView
                let textViewName = String(format: "%@.text", textView.restorationIdentifier!)
                let appBundle = Bundle.main
                let localisedText = NSLocalizedString(textViewName as String, tableName: "Main", bundle: appBundle, value: "", comment: Constant.dummyLocalisationComment)
                if localisedText != "" && localisedText != textViewName {
                    textView.text = localisedText
                }
            }
        })

        userNameTextField.delegate = self
        passwordTextField.delegate = self
        
        userNameTextField.text = User.sharedUser.userName
        passwordTextField.text = User.sharedUser.password

        NotificationCenter.default.addObserver(self, selector: #selector(logonComplete(_:)), name: Constant.notification.logonSuccessful, object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(logonFailed(_:)), name: Constant.notification.logonFailed, object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(connectionFailed(_:)), name: Constant.notification.networkError, object: nil)

        // Register for Keyboard Notifications
        NotificationCenter.default.addObserver(self, selector: #selector(LogonViewController.keyboardWasShown(_:)), name: UIResponder.keyboardDidShowNotification, object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(LogonViewController.keyboardWillBeHidden(_:)), name: UIResponder.keyboardWillHideNotification, object: nil)

        controlLogonButton()
    }
    
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }

    // MARK: Navigation

    // MARK: UITextFieldDelegate
    func textFieldShouldReturn(_ textField: UITextField) -> Bool {
        textField.resignFirstResponder()
        return true
    }

    func textFieldDidBeginEditing(_ textField: UITextField) {
        activeField = textField
    }
    
    func textFieldDidEndEditing(_ textField: UITextField) {
        activeField = nil
    }

    // MARK: Actions
    @IBAction func userNameChanged(_ sender: UITextField) {
        controlLogonButton()
    }
    @IBAction func passwordChanged(_ sender: UITextField) {
        controlLogonButton()
    }
    @IBAction func logon(_ sender: UIButton) {
        User.sharedUser.logon(userName: self.userNameTextField.text!, password: self.passwordTextField.text!)
    }

    

    // MARK: Notifications
    // Called when the UIKeyboardDidShowNotification is sent.
    @objc func keyboardWasShown(_ notification:Notification) {
        let info = notification.userInfo
        let kbSize = (info![UIResponder.keyboardFrameBeginUserInfoKey]! as AnyObject).cgRectValue!.size
        let contentInsets = UIEdgeInsets.init(top: 0.0, left: 0.0, bottom: kbSize.height, right: 0.0);
        scrollView.contentInset = contentInsets;
        scrollView.scrollIndicatorInsets = contentInsets;
        
        // If active text field is hidden by keyboard, scroll it so it's visible
        if let activeField = activeField {
            var aRect = self.view.frame;
            aRect.size.height -= kbSize.height;
            if (!aRect.contains(activeField.frame.origin) ) {
                scrollView.scrollRectToVisible(activeField.frame, animated: true)
            }
        }
    }
    
    // Called when the UIKeyboardWillHideNotification is sent
    @objc func keyboardWillBeHidden(_ notification:Notification) {
        let contentInsets = UIEdgeInsets.zero;
        scrollView.contentInset = contentInsets;
        scrollView.scrollIndicatorInsets = contentInsets;
    }

    @objc func logonComplete(_ notification:Notification) {
        self.dismiss(animated: true, completion: nil)
    }
    
    
    @objc func logonFailed(_ notification:Notification) {
        DispatchQueue.main.async(execute: {
            let alert = UIAlertController(
                title: NSLocalizedString(Constant.msg.logonFailureTitle, comment: Constant.dummyLocalisationComment),
                message: NSLocalizedString(Constant.msg.logonFailureText, comment: Constant.dummyLocalisationComment),
                preferredStyle: UIAlertController.Style.alert)
            
            //Add alert action
            alert.addAction(Constant.alert.actionOK)
            
            //Present alert
            self.present(alert, animated: true, completion: nil)
        })
    }
    
    
    @objc func connectionFailed(_ notification:Notification) {
        DispatchQueue.main.async(execute: {
            let alert = UIAlertController(
                title: NSLocalizedString(Constant.msg.connectErrorTitle, comment: Constant.dummyLocalisationComment),
                message: NSLocalizedString(Constant.msg.connectErrorText, comment: Constant.dummyLocalisationComment),
                preferredStyle: UIAlertController.Style.alert)
            
            //Add alert action
            alert.addAction(Constant.alert.actionOK)
            
            //Present alert
            self.present(alert, animated: true, completion: nil)
        })
    }
    
    
    // MARK: Functions
    func controlLogonButton() {
        if userNameTextField.text == "" || passwordTextField.text == "" {
            logonButton.isEnabled = false
        } else {
            logonButton.isEnabled = true
        }
    }


    func didRecieveResponse(_ results: NSDictionary) {
        // Store the results in our table data array
        print(results)
    }
    
}
