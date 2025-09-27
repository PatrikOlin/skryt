import gleam/dynamic/decode
import gleam/float
import gleam/io
import gleam/time/timestamp
import sqlight

pub type Game {
  Game(id: String, name: String, api_key: String, created_at: Int)
}

pub type GameError {
  DatabaseError(String)
  GameNotFound
  DuplicateGame
}

pub fn create_game(
  db: sqlight.Connection,
  id: String,
  name: String,
  api_key: String,
) -> Result(Game, GameError) {
  let created_at =
    timestamp.system_time()
    |> timestamp.to_unix_seconds()
    |> float.truncate()

  let sql =
    "INSERT INTO games (id, name, api_key, created_at) VALUES (?, ?, ?, ?)"
  case
    sqlight.query(
      sql,
      on: db,
      with: [
        sqlight.text(id),
        sqlight.text(name),
        sqlight.text(api_key),
        sqlight.int(created_at),
      ],
      expecting: decode.dynamic,
    )
  {
    Ok(_) ->
      Ok(Game(id: id, name: name, api_key: api_key, created_at: created_at))
    Error(e) -> Error(DatabaseError(e.message))
  }
}

pub fn verify_game_api_key(
  db: sqlight.Connection,
  game_id: String,
  api_key: String,
) -> Result(Bool, GameError) {
  io.println("Verifying API key: " <> api_key <> " for game: " <> game_id)
  let sql = "SELECT id FROM games WHERE id = ? AND api_key = ? LIMIT 1"

  case
    sqlight.query(
      sql,
      on: db,
      with: [sqlight.text(game_id), sqlight.text(api_key)],
      expecting: decode.dynamic,
    )
  {
    // Found exactly one row
    Ok([_]) -> {
      io.println("API key verification: SUCCESS")
      Ok(True)
    }
    // No rows found
    Ok([]) -> {
      io.println("API key verification: FAILED - no matching game/key")
      Ok(False)
    }
    // Unexpected result
    Ok(_) -> {
      io.println("API key verification: FAILED - unexpected result")
      Ok(False)
    }
    Error(e) -> {
      io.println("API key verification: ERROR - " <> e.message)
      Error(DatabaseError(e.message))
    }
  }
}
