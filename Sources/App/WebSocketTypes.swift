
import Foundation

enum TaskMessageType: String, Codable {
  // Client to server types
  case newTask
  // Server to client types
  case taskResponse, handshake, taskIsDone
}

struct TaskMessageSinData: Codable {
  let type: TaskMessageType
  let id: UUID
}

struct TaskHandshake: Codable {
  var type = TaskMessageType.handshake
  let id: UUID
}

struct NewTaskMessage: Codable {
  let content: String
}

struct NewTaskResponse: Codable {
  var type = TaskMessageType.taskResponse
  let success: Bool
  let message: String
  let id: UUID?
  let isDone: Bool
  let content: String
  let createdAt: Date?
}

struct TaskAnsweredMessage: Codable {
  var type = TaskMessageType.taskIsDone
  let taskId: UUID
}
