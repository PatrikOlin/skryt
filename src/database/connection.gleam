import gleam/dynamic/decode
import gleam/int
import gleam/io
import gleam/list
import sqlight

pub type DatabaseError {
  ConnectionFailed(String)
  MigrationFailed(String)
}

pub fn setup() -> Result(sqlight.Connection, DatabaseError) {
  case sqlight.open("./data/data.db") {
    Ok(db) -> {
      case ensure_migrations(db) {
        Ok(_) -> {
          io.println("Database ready")
          Ok(db)
        }
        Error(e) -> {
          let _ = sqlight.close(db)
          Error(MigrationFailed(e))
        }
      }
    }
    Error(e) -> Error(ConnectionFailed(e.message))
  }
}

fn ensure_migrations(db: sqlight.Connection) -> Result(Nil, String) {
  // check if migrations table exists
  let check_migrations_sql =
    "
    SELECT name FROM sqlite_master
    WHERE type='table' AND name='schema_migrations'
  "
  case
    sqlight.query(
      check_migrations_sql,
      on: db,
      with: [],
      expecting: decode.dynamic,
    )
  {
    Ok([]) -> {
      // No migrations table, run initial setup
      io.println("Setting up database...")
      run_initial_migrations(db)
    }
    Ok(_) -> {
      // Migrations tabels exists, check version
      check_and_run_pending_migrations(db)
    }
    Error(e) -> Error(e.message)
  }
}

fn run_initial_migrations(db: sqlight.Connection) -> Result(Nil, String) {
  let migrations = [
    "CREATE TABLE schema_migrations (version INTEGER PRIMARY KEY)",
    "CREATE TABLE games (
      id TEXT PRIMARY KEY,
      name TEXT NOT NULL,
      api_key TEXT NOT NULL UNIQUE,
      created_at INTEGER NOT NULL
    )",
    "CREATE TABLE scores (
    id INTEGER PRIMARY KEY AUTOINCREMENT,
    game_id TEXT NOT NULL,
    player_name TEXT NOT NULL,
    score INTEGER NOT NULL,
    created_at INTEGER NOT NULL,
    FOREIGN KEY (game_id) REFERENCES games(id)
    )",
    "CREATE INDEX idx_scored_game_score ON scores(game_id, score DESC)",
    "INSERT INTO schema_migrations (version) VALUES (1)",
  ]

  run_migrations(db, migrations)
}

fn check_and_run_pending_migrations(
  db: sqlight.Connection,
) -> Result(Nil, String) {
  // Get current version
  let version_sql = "SELECT MAX(version) FROM schema_migrations"
  io.println("Checking database version...")
  case sqlight.query(version_sql, on: db, with: [], expecting: decode.dynamic) {
    Ok([row]) -> {
      case decode.run(row, decode.at([0], decode.int)) {
        Ok(version) -> {
          io.println("Current database version: " <> int.to_string(version))
          Ok(Nil)
        }
        Error(_) -> {
          io.println("Failed to decode version as integer")
          Error("Failed to decode version")
        }
      }
    }
    Ok([]) -> {
      io.println("No migration version found in existing table")
      Error("No migration version found")
    }
    Ok(results) -> {
      io.println(
        "Multiple version rows found: " <> int.to_string(list.length(results)),
      )
      Error("Multiple version rows found")
    }
    Error(e) -> {
      io.println("Query failed: " <> e.message)
      Error(e.message)
    }
  }
}

fn run_migrations(
  db: sqlight.Connection,
  migrations: List(String),
) -> Result(Nil, String) {
  case migrations {
    [] -> Ok(Nil)
    [sql, ..rest] -> {
      case sqlight.exec(sql, on: db) {
        Ok(_) -> run_migrations(db, rest)
        Error(e) -> Error("Migration failed: " <> e.message)
      }
    }
  }
}
