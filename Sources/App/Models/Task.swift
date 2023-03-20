
import Fluent
import Vapor

final class Task: Model, Content {
  static let schema = "tasks"
  
  @ID(key: .id)
  var id: UUID?

  @Field(key: "content")
  var content: String
  
  @Field(key: "isDone")
  var isDone: Bool
  
  @Field(key: "written_by")
  var written_by: UUID
  
  @Timestamp(key: "created_at", on: .create)
  var createdAt: Date?
  
  init() { }

  init(id: UUID? = nil, content: String, written_by: UUID) {
    self.id = id
    self.content = content
    self.isDone = false
    self.written_by = written_by
  }
}
