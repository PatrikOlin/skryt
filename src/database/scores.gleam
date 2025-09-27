import gleam/dynamic/decode
import gleam/float
import gleam/io
import gleam/list
import gleam/string
import gleam/time/timestamp
import sqlight

pub type Score {
  Score(
    id: Int,
    game_id: String,
    player_name: String,
    score: Int,
    created_at: Int,
  )
}

pub type ScoreError {
  DatabaseError(String)
  GameNotFound
  InvalidScore
}

pub fn add_score_if_worthy(
  db: sqlight.Connection,
  game_id: String,
  player_name: String,
  score: Int,
) -> Result(List(Score), ScoreError) {
  // First, get current top scores for this game
  let current_scores = get_top_scores(db, game_id, 100)

  case current_scores {
    Ok(scores) -> {
      io.println(
        "Found " <> string.inspect(list.length(scores)) <> " existing scores",
      )
      case should_add_score(scores, score) {
        True -> {
          io.println("Score is worthy! Adding to database...")
          case insert_score(db, game_id, player_name, score) {
            Ok(_) -> {
              io.println("Score inserted, getting updated leaderboard...")
              get_top_scores(db, game_id, 100)
            }
            Error(e) -> {
              io.println("insert_score failed: " <> string.inspect(e))
              Error(e)
            }
          }
        }
        False -> {
          io.println("Score not high enough, returning current scores")
          Ok(scores)
        }
      }
    }
    Error(e) -> {
      io.println("get_top_scores failed: " <> string.inspect(e))
      Error(e)
    }
  }
}

fn should_add_score(current_scores: List(Score), new_score: Int) -> Bool {
  case list.length(current_scores) {
    len if len < 100 -> True
    _ -> {
      case list.last(current_scores) {
        Ok(lowest_score) -> new_score > lowest_score.score
        Error(_) -> True
      }
    }
  }
}

fn insert_score(
  db: sqlight.Connection,
  game_id: String,
  player_name: String,
  score: Int,
) -> Result(Nil, ScoreError) {
  io.println(
    "Inserting score: "
    <> string.inspect(score)
    <> " for player: "
    <> player_name,
  )
  let now =
    timestamp.system_time()
    |> timestamp.to_unix_seconds()
    |> float.truncate()

  let sql =
    "INSERT INTO scores (game_id, player_name, score, created_at) VALUES (?, ?, ?, ?)"

  case
    sqlight.query(
      sql,
      on: db,
      with: [
        sqlight.text(game_id),
        sqlight.text(player_name),
        sqlight.int(score),
        sqlight.int(now),
      ],
      expecting: decode.dynamic,
    )
  {
    Ok(_) -> cleanup_excess_scores(db, game_id)
    Error(e) -> {
      io.println("Error inserting score: " <> e.message)
      io.println("Game ID: " <> string.inspect(e.code))
      Error(DatabaseError(e.message))
    }
  }
}

fn cleanup_excess_scores(
  db: sqlight.Connection,
  game_id: String,
) -> Result(Nil, ScoreError) {
  let sql =
    "
    DELETE FROM scores
    WHERE game_id = ?
    AND id NOT IN (
      SELECT id FROM scores
      WHERE game_id = ?
      ORDER BY score DESC
      LIMIT 100
    )"

  case
    sqlight.query(
      sql,
      on: db,
      with: [sqlight.text(game_id), sqlight.text(game_id)],
      expecting: decode.dynamic,
    )
  {
    Ok(_) -> Ok(Nil)
    Error(e) -> Error(DatabaseError(e.message))
  }
}

pub fn get_top_scores(
  db: sqlight.Connection,
  game_id: String,
  limit: Int,
) -> Result(List(Score), ScoreError) {
  let sql =
    "
    SELECT id, game_id, player_name, score, created_at
    FROM scores
    WHERE game_id = ?
    ORDER BY score DESC, created_at ASC
    LIMIT ?"

  case
    sqlight.query(
      sql,
      on: db,
      with: [sqlight.text(game_id), sqlight.int(limit)],
      expecting: score_decoder(),
    )
  {
    Ok(scores) -> Ok(scores)
    Error(e) -> {
      io.println("Query failed: " <> e.message)
      Error(DatabaseError(e.message))
    }
  }
}

fn score_decoder() -> decode.Decoder(Score) {
  {
    use id <- decode.field(0, decode.int)
    use game_id <- decode.field(1, decode.string)
    use player_name <- decode.field(2, decode.string)
    use score <- decode.field(3, decode.int)
    use created_at <- decode.field(4, decode.int)
    decode.success(Score(
      id: id,
      game_id: game_id,
      player_name: player_name,
      score: score,
      created_at: created_at,
    ))
  }
}
