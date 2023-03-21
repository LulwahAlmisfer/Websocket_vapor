
import Fluent
import Vapor
import Leaf

struct TasksController: RouteCollection {
  let wsController: WebSocketController
  
  func boot(routes: RoutesBuilder) throws {
    routes.webSocket("socket", onUpgrade: self.webSocket)
    routes.get(use: index)
    routes.post(":TaskId", "Done", use: done)
    routes.put(use: update)
    routes.delete(":TaskId" ,use: delete)
      
  }
  
  func webSocket(req: Request, socket: WebSocket) {
    self.wsController.connect(socket)
  }
  
  struct TasksContext: Encodable {
    let tasks: [Task]
  }

  func index(req: Request) throws -> EventLoopFuture<[Task]>{
    // 1
      return  Task.query(on: req.db).all()
  }
  
  func done(req: Request) throws -> EventLoopFuture<HTTPStatus> {
    // 1
    guard let taskId = req.parameters.get("TaskId"), let taskUid = UUID(taskId) else {
      throw Abort(.badRequest)
    }
    // 2
    return Task.find(taskUid, on: req.db).unwrap(or: Abort(.notFound)).flatMap { task in
      task.isDone = true
      // 3
      return task.save(on: req.db).flatMapThrowing {
        // 4
          try self.wsController.send(message: TaskAnsweredMessage(taskId: task.requireID()), to: .id(task.written_by))
        // 5
          return .ok
      }
    }
  }
    
    func update(req: Request) async throws -> HTTPStatus {
          let task = try req.content.decode(Task.self)
          
          guard let taskFromDB = try await Task.find(task.id, on: req.db) else {
              throw Abort(.notFound)
          }
          
        taskFromDB.content = task.content
          try await taskFromDB.update(on: req.db)
          return .ok
      }
    
    func delete(req: Request) async throws -> HTTPStatus {
           guard let task = try await Task.find(req.parameters.get("TaskId"), on: req.db) else {
               throw Abort(.notFound)
           }
        
           try await task.delete(on: req.db)
           return .ok
       }
}
