
import Vapor
import Fluent

enum WebSocketSendOption {
  case id(UUID), socket(WebSocket)
}

class WebSocketController {
  let lock: Lock
  var sockets: [UUID: WebSocket]
  let db: Database
  let logger: Logger
  
  init(db: Database) {
    self.lock = Lock()
    self.sockets = [:]
    self.db = db
    self.logger = Logger(label: "WebSocketController")
  }
  
  func connect(_ ws: WebSocket) {
    // 1
    let uuid = UUID()
    self.lock.withLockVoid {
      self.sockets[uuid] = ws
    }
    // 2
    ws.onBinary { [weak self] ws, buffer in
      guard let self = self, let data = buffer.getData(at: buffer.readerIndex, length: buffer.readableBytes) else { return }
      self.onData(ws, data)
    }
    // 3
    ws.onText { [weak self] ws, text in
      guard let self = self, let data = text.data(using: .utf8) else { return }
      self.onData(ws, data)
    }
    // 4
    self.send(message: TaskHandshake(id: uuid), to: .socket(ws))
  }
  
  func send<T: Codable>(message: T, to sendOption: WebSocketSendOption) {
    logger.info("Sending \(T.self) to \(sendOption)")
    do {
      // 1
      let sockets: [WebSocket] = self.lock.withLock {
        switch sendOption {
        case .id(let id):
          return [self.sockets[id]].compactMap { $0 }
        case .socket(let socket):
          return [socket]
        }
      }
      
      // 2
      let encoder = JSONEncoder()
      let data = try encoder.encode(message)
      
      // 3
      sockets.forEach {
        $0.send(raw: data, opcode: .binary)
      }
    } catch {
      logger.report(error: error)
    }
  }
  
  func onNewTask(_ ws: WebSocket, _ id: UUID, _ message: NewTaskMessage) {
    let q = Task(content: message.content, written_by: id)
    self.db.withConnection {
      // 1
      q.save(on: $0)
    }.whenComplete { res in
      let success: Bool
      let message: String
      switch res {
      case .failure(let err):
        // 2
        self.logger.report(error: err)
        success = false
        message = "Something went wrong creating the task."
      case .success:
        // 3
        self.logger.info("Got a new task!")
        success = true
        message = "task created. We will answer it as soon as possible :]"
      }
      // 4
      try? self.send(message: NewTaskResponse(
        success: success,
        message: message,
        id: q.requireID(),
        isDone: q.isDone,
        content: q.content,
        createdAt: q.createdAt
      ), to: .socket(ws))
    }
  }
  
  func onData(_ ws: WebSocket, _ data: Data) {
    let decoder = JSONDecoder()
    do {
      // 1
      let sinData = try decoder.decode(TaskMessageSinData.self, from: data)
      // 2
      switch sinData.type {
      case .newTask:
        // 3
        let newTaskData = try decoder.decode(NewTaskMessage.self, from: data)
        self.onNewTask(ws, sinData.id, newTaskData)
      default:
        break
      }
    } catch {
      logger.report(error: error)
    }
  }
}
