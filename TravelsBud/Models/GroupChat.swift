import Foundation
import FirebaseFirestore

// GroupChat Model (REMOVE THIS)
struct GroupChat: Identifiable {
    var id: String
    let title: String
    let creatorID: String
    var participants: [String]
    let timestamp: Date
    var messages: [Message] = [] // This should only exist in GroupChat.swift
}
