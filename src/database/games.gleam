import gleam/dynamic/decode
import gleam/float
import gleam/int
import gleam/io
import gleam/time/timestamp
import sqlight

pub type Game {
  Game(id: String, name: String, slug: String, api_key: String, created_at: Int)
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
  slug: String,
  api_key: String,
) -> Result(Game, GameError) {
  let created_at =
    timestamp.system_time()
    |> timestamp.to_unix_seconds()
    |> float.truncate()

  let sql =
    "INSERT INTO games (id, name, slug, api_key, created_at) VALUES (?, ?, ?, ?, ?) RETURNING *"
  case
    sqlight.query(
      sql,
      on: db,
      with: [
        sqlight.text(id),
        sqlight.text(name),
        sqlight.text(slug),
        sqlight.text(api_key),
        sqlight.int(created_at),
      ],
      expecting: game_decoder(),
    )
  {
    Ok([game]) -> Ok(game)
    Ok([]) -> {
      io.print_error("No game created, no rows affected")
      Error(DatabaseError("Failed to create game, no rows affected"))
    }
    Ok(_) -> {
      io.print_error("Multiple games created with same ID/slug")
      Error(DuplicateGame)
    }
    Error(e) -> {
      io.print_error("Error creating game: " <> e.message)
      Error(DatabaseError(e.message))
    }
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

pub fn slug_exists(
  db: sqlight.Connection,
  slug: String,
) -> Result(Bool, GameError) {
  let sql = "SELECT COUNT(*) FROM games WHERE slug = ?"
  case
    sqlight.query(
      sql,
      on: db,
      with: [sqlight.text(slug)],
      expecting: count_decoder(),
    )
  {
    Ok([count]) -> Ok(count > 0)
    Ok([]) -> Ok(False)
    Ok(_) -> Ok(False)
    Error(e) -> Error(DatabaseError(e.message))
  }
}

fn count_decoder() -> decode.Decoder(Int) {
  use count <- decode.field(0, decode.int)
  decode.success(count)
}

// Helper function to find a unique slug
pub fn ensure_unique_slug(
  db: sqlight.Connection,
  base_slug: String,
) -> Result(String, GameError) {
  case slug_exists(db, base_slug) {
    Ok(False) -> Ok(base_slug)
    // Base slug is available
    Ok(True) -> find_available_slug(db, base_slug, 2)
    // Try with numbers
    Error(e) -> Error(e)
  }
}

fn find_available_slug(
  db: sqlight.Connection,
  base_slug: String,
  counter: Int,
) -> Result(String, GameError) {
  let candidate_slug = base_slug <> "-" <> int.to_string(counter)
  case slug_exists(db, candidate_slug) {
    Ok(False) -> Ok(candidate_slug)
    Ok(True) -> find_available_slug(db, base_slug, counter + 1)
    Error(e) -> Error(e)
  }
}

pub fn get_game_by_slug(
  db: sqlight.Connection,
  slug: String,
) -> Result(Game, GameError) {
  let sql =
    "SELECT id, name, slug, api_key, created_at FROM games WHERE slug = ? LIMIT 1"

  case
    sqlight.query(
      sql,
      on: db,
      with: [sqlight.text(slug)],
      expecting: game_decoder(),
    )
  {
    Ok([game]) -> Ok(game)
    Ok([]) -> Error(GameNotFound)
    Ok(_) -> Error(DatabaseError("Unexpected result, multiple games found"))
    Error(e) -> Error(DatabaseError(e.message))
  }
}

fn game_decoder() -> decode.Decoder(Game) {
  {
    use id <- decode.field(0, decode.string)
    use name <- decode.field(1, decode.string)
    use slug <- decode.field(2, decode.string)
    use api_key <- decode.field(3, decode.string)
    use created_at <- decode.field(4, decode.int)
    decode.success(Game(
      id: id,
      name: name,
      slug: slug,
      api_key: api_key,
      created_at: created_at,
    ))
  }
}
