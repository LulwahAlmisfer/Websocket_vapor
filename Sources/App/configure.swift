
import Fluent
import FluentPostgresDriver
import Vapor

// configures your application
public func configure(_ app: Application) throws {
  // Configure rendering engine
 // app.views.use(.leaf)

  // Configure database
    app.databases.use(.postgres(
      hostname: Environment.get("DATABASE_HOST")
        ?? "localhost",
      username: Environment.get("DATABASE_USERNAME")
        ?? "vapor_username",
      password: Environment.get("DATABASE_PASSWORD")
        ?? "vapor_password",
      database: Environment.get("DATABASE_NAME")
        ?? "vapor_database"
    ), as: .psql)
    
  app.migrations.add(CreateTask())
  
  // Run migrations at app startup.
  try app.autoMigrate().wait()

  // register routes
  try routes(app)
}
