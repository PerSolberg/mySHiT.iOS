//
//  SettingsViewController.swift
//  mySHiT
//
//  Created by Per Solberg on 2015-10-09.
//  Copyright © 2015 Per Solberg. All rights reserved.
//

import UIKit

class LogonViewController: UIViewController, UITextFieldDelegate {
    //
    // MARK: Properties
    //
    @IBOutlet weak var userNameTextField: UITextField!
    @IBOutlet weak var passwordTextField: UITextField!
    @IBOutlet weak var logonButton: UIButton!
    
    var activeField: UITextField?
    
    
    //
    // MARK: Callbacks
    //
    @IBOutlet weak var scrollView: UIScrollView!

    override func viewDidLoad() {
        super.viewDidLoad()

        // Fix localisation for UITextView
        self.view.processSubviews(true, processChildrenFirst: true, action: { (view:UIView, level:Int) in
            if view.isKind(of: UITextView.self) && view.restorationIdentifier != nil {
                let textView = view as! UITextView
                let textViewName = String(format: "%@.text", textView.restorationIdentifier!)
                let localisedText = AppStoryboard.Main.localizedString(textViewName)
                
                if localisedText != "" && localisedText != textViewName {
                    textView.text = localisedText
                }
            }
        })

        userNameTextField.delegate = self
        passwordTextField.delegate = self
        
        userNameTextField.text = User.sharedUser.userName
        passwordTextField.text = User.sharedUser.password

        NotificationCenter.default.addObserver(self, selector: #selector(logonComplete(_:)), name: Constant.Notification.logonSuccessful, object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(logonFailed(_:)), name: Constant.Notification.logonFailed, object: nil)

        // Register for Keyboard Notifications
        NotificationCenter.default.addObserver(self, selector: #selector(LogonViewController.keyboardWasShown(_:)), name: UIResponder.keyboardDidShowNotification, object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(LogonViewController.keyboardWillBeHidden(_:)), name: UIResponder.keyboardWillHideNotification, object: nil)

        controlLogonButton()
    }
    
    
    override func viewWillAppear(_ animated: Bool) {
        NotificationCenter.default.addObserver(self, selector: #selector(connectionFailed(_:)), name: Constant.Notification.networkError, object: nil)
    }

    
    override func viewWillDisappear(_ animated: Bool) {
        NotificationCenter.default.removeObserver(self, name: Constant.Notification.networkError, object: nil)
    }

    
    //
    // MARK: Navigation
    //


    //
    // MARK: UITextFieldDelegate
    //
    func textFieldDidBeginEditing(_ textField: UITextField) {
        activeField = textField
    }
    
    
    func textFieldDidEndEditing(_ textField: UITextField) {
        activeField = nil
    }

    
    //
    // MARK: Actions
    //
    @IBAction func userNameChanged(_ sender: UITextField) {
        controlLogonButton()
    }
    
    
    @IBAction func passwordChanged(_ sender: UITextField) {
        controlLogonButton()
    }
    
    
    @IBAction func logon(_ sender: UIButton) {
        User.sharedUser.logon(userName: self.userNameTextField.text!, password: self.passwordTextField.text!)
    }

    
    @IBAction func enterKeyPassword(_ sender: Any) {
        if logonButton.isEnabled {
            passwordTextField.resignFirstResponder()
            logon(logonButton)
        }
    }
    
    
    @IBAction func enterKeyUserName(_ sender: Any) {
        passwordTextField.becomeFirstResponder()
    }

    
    //
    // MARK: Notifications
    //
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
        DispatchQueue.main.async(execute: {
            self.dismiss(animated: true, completion: nil)
        })
    }
    
    
    @objc func logonFailed(_ notification:Notification) {
        showAlert(title: Constant.Message.logonFailureTitle, message: Constant.Message.logonFailureText, completion: nil)
    }
    
    
    @objc func connectionFailed(_ notification:Notification) {
        showAlert(title: Constant.Message.connectErrorTitle, message: Constant.Message.connectErrorText, completion: nil)
    }
    
    
    // MARK: Functions
    func controlLogonButton() {
        if userNameTextField.text == "" || passwordTextField.text == "" {
            logonButton.isEnabled = false
        } else {
            logonButton.isEnabled = true
        }
    }
 
}
