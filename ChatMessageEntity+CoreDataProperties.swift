//
//  ChatMessageEntity+CoreDataProperties.swift
//  PRO version 0.0
//
//  Created by Maria Nikolaeva on 10.04.2025.
//

import Foundation
import CoreData

extension ChatMessageEntity {

    @nonobjc public class func fetchRequest() -> NSFetchRequest<ChatMessageEntity> {
        return NSFetchRequest<ChatMessageEntity>(entityName: "ChatMessageEntity")
    }

    @NSManaged public var content: String?
    @NSManaged public var id: UUID?
    @NSManaged public var isUser: Bool
    @NSManaged public var timestamp: Date?
    @NSManaged public var conversation: ChatConversationEntity?

}
