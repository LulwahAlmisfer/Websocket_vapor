
import Fluent
import Vapor

func routes(_ app: Application) throws {
  let webSocketController = WebSocketController(db: app.db)
  try app.register(collection: TasksController(wsController: webSocketController))
}
