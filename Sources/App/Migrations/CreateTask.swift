
import Fluent

struct CreateTask: Migration {
  func prepare(on database: Database) -> EventLoopFuture<Void> {
    return database.schema(Task.schema)
      .id()
      .field("content", .string, .required)
      .field("isDone", .bool, .required, .sql(.default(false)))
      .field("written_by", .uuid, .required)
      .field("created_at", .date)
      .create()
  }

  func revert(on database: Database) -> EventLoopFuture<Void> {
    return database.schema(Task.schema).delete()
  }
}
