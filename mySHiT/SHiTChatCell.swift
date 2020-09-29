//
//  SHiTChatCell.swift
//  mySHiT
//
//  Created by Per Solberg on 2017-03-29.
//  Copyright © 2017 &More AS. All rights reserved.
//

import UIKit

class SHiTChatCell: UITableViewCell {
    static let speechBubbleLayerName = "speechBubble"
    static let colourOwnMessage = UIColor.init(red: 0.8, green: 1.0, blue: 0.8, alpha: 1.0).cgColor
    static let colourUnsavedMessage = UIColor.init(red: 1.0, green: 1.0, blue: 0.8, alpha: 1.0).cgColor
    static let colourOtherMessage = UIColor.init(red: 0.8, green: 1.0, blue: 1.0, alpha: 1.0).cgColor
    static let colourUnsavedMessageBorder = UIColor.init(red: 0.6, green: 0.8, blue: 0.6, alpha: 1.0).cgColor
    static let dashUnsavedMessageBorder:[NSNumber] = [2, 2]
    static let borderWidth: CGFloat = 1.0
    static let radius: CGFloat = 6.0
    static let triangleHeight: CGFloat = 8.0
    
    @IBOutlet weak var seenByUsersText: UITextView!
    @IBOutlet weak var userInitialsLabel: UILabel!
    @IBOutlet weak var messageText: UITextView!
    var message:ChatMessage?
 
    override func awakeFromNib() {
        super.awakeFromNib()
        messageText.textContainerInset = UIEdgeInsets.zero
    }

    
    override func layoutSubviews() {
        messageText.sizeToFit()
        self.contentView.layoutSubviews()
        super.layoutSubviews()

        addSpeechBubble()
    }

    public func addSpeechBubble() {
        guard let message = message else {
            fatalError("Cell not set up correctly, message missing")
        }
        
        let bubbleLayer = CAShapeLayer()
        bubbleLayer.name = SHiTChatCell.speechBubbleLayerName
        
        if message.userId == User.sharedUser.userId {
            bubbleLayer.path = messageText.bubblePath(borderWidth: SHiTChatCell.borderWidth, radius: SHiTChatCell.radius, triangleHeight: SHiTChatCell.triangleHeight, triangleEdge: .right, trianglePosition: .top).cgPath
            if message.isStored {
                bubbleLayer.fillColor = SHiTChatCell.colourOwnMessage
            } else {
                bubbleLayer.fillColor = SHiTChatCell.colourUnsavedMessage
                bubbleLayer.strokeColor = SHiTChatCell.colourUnsavedMessageBorder
                bubbleLayer.lineDashPattern = SHiTChatCell.dashUnsavedMessageBorder
            }
        } else {
            bubbleLayer.path = messageText.bubblePath(borderWidth: SHiTChatCell.borderWidth, radius: SHiTChatCell.radius, triangleHeight: SHiTChatCell.triangleHeight, triangleEdge: .left, trianglePosition: .top).cgPath
            bubbleLayer.fillColor = SHiTChatCell.colourOtherMessage
        }

        bubbleLayer.lineWidth = SHiTChatCell.borderWidth
        bubbleLayer.position = CGPoint(x: messageText.frame.minX - SHiTChatCell.radius, y: messageText.frame.minY - SHiTChatCell.radius) // CGPoint.zero
        
        var speechBubbleExists = false
        if let sublayers = self.contentView.layer.sublayers {
            for sl in sublayers {
                if sl.name == SHiTChatCell.speechBubbleLayerName {
                    self.contentView.layer.replaceSublayer(sl, with: bubbleLayer)
                    speechBubbleExists = true
                    break;
                }
            }
        }
        if !speechBubbleExists {
            self.contentView.layer.insertSublayer(bubbleLayer, below: messageText.layer)
        }
    }

}
