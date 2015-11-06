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
    
    // MARK: Callbacks
    override func viewDidLoad() {
        super.viewDidLoad()

        // Fix localisation for UITextView
        self.view.processSubviews(true, processChildrenFirst: true, action: { (view:UIView, level:Int) in
            //print("processing view \(view.restorationIdentifier)")
            if view.isKindOfClass(UITextView) && view.restorationIdentifier != nil {
                print("Found UITextView \(view.restorationIdentifier!)")
                let textView = view as! UITextView
                let textViewName = NSString(format: "%@.text", textView.restorationIdentifier!)
                let appBundle = NSBundle.mainBundle()
                let localisedText = NSLocalizedString(textViewName as String, tableName: "Main", bundle: appBundle, value: "", comment: "dummy")
                if localisedText != "" {
                    textView.text = localisedText
                }
            }
        })

        userNameTextField.delegate = self
        passwordTextField.delegate = self
        
        userNameTextField.text = User.sharedUser.userName
        passwordTextField.text = User.sharedUser.password

        NSNotificationCenter.defaultCenter().addObserver(self, selector: "logonComplete:", name:"logonSuccessful", object: nil)

        controlLogonButton()
        //api.delegate = self;
    }
    
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }

    // MARK: Navigation

    // MARK: UITextFieldDelegate
    func textFieldShouldReturn(textField: UITextField) -> Bool {
        textField.resignFirstResponder()
        return true
    }
    
    // MARK: Actions
    @IBAction func userNameChanged(sender: UITextField) {
        controlLogonButton()
    }
    @IBAction func passwordChanged(sender: UITextField) {
        controlLogonButton()
    }
    @IBAction func logon(sender: UIButton) {
        //messageTextView.text = "Current password = \(passwordTextField.text)"

        //check to see if host is reachable
        if (!RSUtilities.isNetworkAvailable("www.shitt.no")) {
            _ = RSUtilities.networkConnectionType("www.shitt.no")
            
            //If host is not reachable, display a UIAlertController informing the user
            let alert = UIAlertController(title: "Alert", message: "You are not connected to the Internet", preferredStyle: UIAlertControllerStyle.Alert)
            
            //Add alert action
            alert.addAction(UIAlertAction(title: "OK", style: UIAlertActionStyle.Default, handler: nil))
            
            //Present alert
            self.presentViewController(alert, animated: true, completion: nil)
            
        }
        
        User.sharedUser.logon(userName: self.userNameTextField.text!, password: self.passwordTextField.text!)
    }


    // MARK: Notifications
    func logonComplete(notification:NSNotification) {
        self.dismissViewControllerAnimated(true, completion: nil)
    }
    
    
    // MARK: Functions
    func controlLogonButton() {
        if userNameTextField.text == "" || passwordTextField.text == "" {
            logonButton.enabled = false
        } else {
            logonButton.enabled = true
        }
    }


    func didRecieveResponse(results: NSDictionary) {
        // Store the results in our table data array
        print(results)
    }
    
}
