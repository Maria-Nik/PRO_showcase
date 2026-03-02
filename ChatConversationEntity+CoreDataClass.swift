//
//  ChatConversationEntity+CoreDataClass.swift
//  PRO version 0.0
//
//  Created by Maria Nikolaeva on 10.04.2025.
//

import Foundation
import CoreData

@objc(ChatConversationEntity)
public class ChatConversationEntity: NSManagedObject {
    
    // MARK: - Convenience Methods
    
    /// Create a new conversation
    static func createConversation(in context: NSManagedObjectContext, title: String? = nil) -> ChatConversationEntity {
        let conversation = ChatConversationEntity(context: context)
        conversation.id = UUID()
        conversation.createdAt = Date()
        conversation.lastMessageAt = Date()
        conversation.title = title ?? "New Conversation"
        return conversation
    }
    
    /// Add a message to this conversation
    func addMessage(content: String, isUser: Bool, in context: NSManagedObjectContext) -> ChatMessageEntity {
        let message = ChatMessageEntity(context: context)
        message.id = UUID()
        message.content = content
        message.isUser = isUser
        message.timestamp = Date()
        message.conversation = self
        
        // Update conversation's last message timestamp
        self.lastMessageAt = Date()
        
        // Update title if this is the first user message
        if self.messages?.count == 1 && isUser {
            self.title = content.count > 30 ? String(content.prefix(30)) + "..." : content
        }
        
        return message
    }
    
    /// Get sorted messages for this conversation
    var sortedMessages: [ChatMessageEntity] {
        guard let messages = messages as? Set<ChatMessageEntity> else { return [] }
        return messages.sorted { $0.timestamp ?? Date() < $1.timestamp ?? Date() }
    }
    
    /// Get the last message in this conversation
    var lastMessage: ChatMessageEntity? {
        return sortedMessages.last
    }
    
    /// Get a preview of the last message
    var lastMessagePreview: String {
        guard let lastMessage = lastMessage else { return "No messages yet" }
        let content = lastMessage.content ?? ""
        return content.count > 50 ? String(content.prefix(50)) + "..." : content
    }
    
    /// Get formatted date for display
    var formattedDate: String {
        guard let date = lastMessageAt else { return "" }
        let formatter = DateFormatter()
        formatter.dateStyle = .short
        formatter.timeStyle = .short
        return formatter.string(from: date)
    }
}
