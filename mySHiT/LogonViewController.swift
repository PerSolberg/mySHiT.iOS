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
            //print("processing view \(view.restorationIdentifier)")
            if view.isKind(of: UITextView.self) && view.restorationIdentifier != nil {
                print("Found UITextView \(view.restorationIdentifier!)")
                let textView = view as! UITextView
                let textViewName = String(format: "%@.text", textView.restorationIdentifier!)
                let appBundle = Bundle.main
                let localisedText = NSLocalizedString(textViewName as String, tableName: "Main", bundle: appBundle, value: "", comment: "dummy")
                if localisedText != "" && localisedText != textViewName {
                    textView.text = localisedText
                }
            }
        })

        userNameTextField.delegate = self
        passwordTextField.delegate = self
        
        userNameTextField.text = User.sharedUser.userName
        passwordTextField.text = User.sharedUser.password

        NotificationCenter.default.addObserver(self, selector: #selector(LogonViewController.logonComplete(_:)), name: NSNotification.Name(rawValue: Constant.notification.logonSuccessful), object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(LogonViewController.logonFailed(_:)), name: NSNotification.Name(rawValue: Constant.notification.logonFailed), object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(LogonViewController.connectionFailed(_:)), name: NSNotification.Name(rawValue: Constant.notification.networkError), object: nil)

        // Register for Keyboard Notifications
        NotificationCenter.default.addObserver(self, selector: #selector(LogonViewController.keyboardWasShown(_:)), name: NSNotification.Name.UIKeyboardDidShow, object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(LogonViewController.keyboardWillBeHidden(_:)), name: NSNotification.Name.UIKeyboardWillHide, object: nil)
                    //name:UIKeyboardWillHideNotification object:nil];

        controlLogonButton()
        //api.delegate = self;
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
        //messageTextView.text = "Current password = \(passwordTextField.text)"

        //check to see if host is reachable
        /*
        if (!RSUtilities.isNetworkAvailable("www.shitt.no")) {
            _ = RSUtilities.networkConnectionType("www.shitt.no")
            
            //If host is not reachable, display a UIAlertController informing the user
            let alert = UIAlertController(
                title: NSLocalizedString(Constant.msg.alertBoxTitle, comment: "Some dummy comment"),
                message: NSLocalizedString(Constant.msg.connectError, comment: "Some dummy comment"),
                preferredStyle: UIAlertControllerStyle.Alert)
            
            //Add alert action
            alert.addAction(UIAlertAction(title: "OK", style: UIAlertActionStyle.Default, handler: nil))
            
            //Present alert
            self.presentViewController(alert, animated: true, completion: nil)
            
        }
        */
        
        User.sharedUser.logon(userName: self.userNameTextField.text!, password: self.passwordTextField.text!)
    }

    

    // MARK: Notifications
    // Called when the UIKeyboardDidShowNotification is sent.
    func keyboardWasShown(_ notification:Notification) {
        //let scrollView = self.view
        let info = notification.userInfo
        let kbSize = (info![UIKeyboardFrameBeginUserInfoKey]! as AnyObject).cgRectValue!.size
        let contentInsets = UIEdgeInsetsMake(0.0, 0.0, kbSize.height, 0.0);
        scrollView.contentInset = contentInsets;
        scrollView.scrollIndicatorInsets = contentInsets;
        
        // If active text field is hidden by keyboard, scroll it so it's visible
        // Your app might not need or want this behavior.
        if let activeField = activeField {
            var aRect = self.view.frame;
            aRect.size.height -= kbSize.height;
            if (!aRect.contains(activeField.frame.origin) ) {
                scrollView.scrollRectToVisible(activeField.frame, animated: true)
                //[self.scrollView scrollRectToVisible:activeField.frame animated:YES];
            }
        }
    }
    
    // Called when the UIKeyboardWillHideNotification is sent
    func keyboardWillBeHidden(_ notification:Notification) {
        let contentInsets = UIEdgeInsets.zero;
        scrollView.contentInset = contentInsets;
        scrollView.scrollIndicatorInsets = contentInsets;
    }

    func logonComplete(_ notification:Notification) {
        self.dismiss(animated: true, completion: nil)
    }
    
    
    func logonFailed(_ notification:Notification) {
        print("LogonViewController: logonFailed")
        DispatchQueue.main.async(execute: {
            let alert = UIAlertController(
                title: NSLocalizedString(Constant.msg.logonFailureTitle, comment: "Some dummy comment"),
                message: NSLocalizedString(Constant.msg.logonFailureText, comment: "Some dummy comment"),
                preferredStyle: UIAlertControllerStyle.alert)
            
            //Add alert action
            alert.addAction(UIAlertAction(title: "OK", style: UIAlertActionStyle.default, handler: nil))
            
            //Present alert
            self.present(alert, animated: true, completion: nil)
        })
    }
    
    
    func connectionFailed(_ notification:Notification) {
        print("LogonViewController: connectionFailed")
        DispatchQueue.main.async(execute: {
            let alert = UIAlertController(
                title: NSLocalizedString(Constant.msg.connectErrorTitle, comment: "Some dummy comment"),
                message: NSLocalizedString(Constant.msg.connectErrorText, comment: "Some dummy comment"),
                preferredStyle: UIAlertControllerStyle.alert)
            
            //Add alert action
            alert.addAction(UIAlertAction(title: "OK", style: UIAlertActionStyle.default, handler: nil))
            
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
