//
//  ChatMessageEntity+CoreDataClass.swift
//  PRO version 0.0
//
//  Created by Maria Nikolaeva on 10.04.2025.
//

import Foundation
import CoreData

@objc(ChatMessageEntity)
public class ChatMessageEntity: NSManagedObject {
    
    // MARK: - Convenience Methods
    
    /// Create a new message
    static func createMessage(in context: NSManagedObjectContext, content: String, isUser: Bool, conversation: ChatConversationEntity) -> ChatMessageEntity {
        let message = ChatMessageEntity(context: context)
        message.id = UUID()
        message.content = content
        message.isUser = isUser
        message.timestamp = Date()
        message.conversation = conversation
        return message
    }
    
    /// Get formatted timestamp for display
    var formattedTimestamp: String {
        guard let timestamp = timestamp else { return "" }
        let formatter = DateFormatter()
        formatter.timeStyle = .short
        return formatter.string(from: timestamp)
    }
    
    /// Get relative time (e.g., "2 minutes ago")
    var relativeTime: String {
        guard let timestamp = timestamp else { return "" }
        let now = Date()
        let timeInterval = now.timeIntervalSince(timestamp)
        
        if timeInterval < 60 {
            return "Just now"
        } else if timeInterval < 3600 {
            let minutes = Int(timeInterval / 60)
            return "\(minutes) min ago"
        } else if timeInterval < 86400 {
            let hours = Int(timeInterval / 3600)
            return "\(hours)h ago"
        } else {
            let days = Int(timeInterval / 86400)
            return "\(days)d ago"
        }
    }
}
