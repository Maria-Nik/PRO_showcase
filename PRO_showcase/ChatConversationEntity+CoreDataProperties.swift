//
//  ChatConversationEntity+CoreDataProperties.swift
//  PRO version 0.0
//
//  Created by Maria Nikolaeva on 10.04.2025.
//

import Foundation
import CoreData

extension ChatConversationEntity {

    @nonobjc public class func fetchRequest() -> NSFetchRequest<ChatConversationEntity> {
        return NSFetchRequest<ChatConversationEntity>(entityName: "ChatConversationEntity")
    }

    @NSManaged public var createdAt: Date?
    @NSManaged public var id: UUID?
    @NSManaged public var lastMessageAt: Date?
    @NSManaged public var title: String?
    @NSManaged public var messages: NSSet?

}

// MARK: Generated accessors for messages
extension ChatConversationEntity {

    @objc(addMessagesObject:)
    @NSManaged public func addToMessages(_ value: ChatMessageEntity)

    @objc(removeMessagesObject:)
    @NSManaged public func removeFromMessages(_ value: ChatMessageEntity)

    @objc(addMessages:)
    @NSManaged public func addToMessages(_ values: NSSet)

    @objc(removeMessages:)
    @NSManaged public func removeFromMessages(_ values: NSSet)

}
