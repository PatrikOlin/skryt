import database/games
import database/scores
import gleam/dynamic/decode
import gleam/http.{Get, Post}
import gleam/int
import gleam/io
import gleam/json
import gleam/list
import gleam/option.{None, Some}
import gleam/string
import web
import wisp.{type Request, type Response}

pub type SubmitScoreRequest {
  SubmitScoreRequest(player_name: String, score: Int)
}

fn submit_score_request_decoder() -> decode.Decoder(SubmitScoreRequest) {
  use player_name <- decode.field("player_name", decode.string)
  use score <- decode.field("score", decode.int)
  decode.success(SubmitScoreRequest(player_name:, score:))
}

pub fn scores_handler(
  req: Request,
  ctx: web.Context,
  game_id: String,
) -> Response {
  case req.method {
    Get -> list_scores(ctx, game_id)
    Post -> create_score(req, ctx, game_id)
    _ -> wisp.method_not_allowed([Get, Post])
  }
}

fn create_score(req: Request, ctx: web.Context, game_id: String) -> Response {
  use json <- wisp.require_json(req)

  case ctx.api_key {
    Some(api_key) -> {
      case decode.run(json, submit_score_request_decoder()) {
        Ok(score_request) -> {
          // validate and normalize player name
          case validate_player_name(score_request.player_name) {
            Ok(clean_name) -> {
              case games.verify_game_api_key(ctx.db, game_id, api_key) {
                Ok(_) -> {
                  case
                    scores.add_score_if_worthy(
                      ctx.db,
                      game_id,
                      clean_name,
                      score_request.score,
                    )
                  {
                    Ok(updated_scores) -> {
                      io.println(
                        "Score added successfully! Total scores: "
                        <> int.to_string(list.length(updated_scores)),
                      )
                      let response_json =
                        json.object([
                          #("scores", json.array(updated_scores, score_to_json)),
                        ])
                        |> json.to_string

                      wisp.json_response(response_json, 200)
                    }
                    Error(score_error) -> {
                      io.println(
                        "Score addition failed with error: "
                        <> string.inspect(score_error),
                      )
                      wisp.internal_server_error()
                      |> wisp.json_body("{\"errror\": \"Failed to add score\"}")
                    }
                  }
                }
                Error(_) -> {
                  io.println("API key verification failed")
                  wisp.json_response("{\"error\": \"Invalid API key\"}", 403)
                }
              }
            }
            Error(msg) -> {
              io.println("Name validation failed: " <> msg)
              wisp.bad_request(msg)
              |> wisp.json_body("{\"error\": \"" <> msg <> "\"}")
            }
          }
        }
        Error(decode_error) -> {
          io.println("JSON decode failed: " <> string.inspect(decode_error))
          wisp.unprocessable_content()
        }
      }
    }
    None -> {
      io.println("API key verification failed")
      wisp.json_response("{\"error\": \"Invalid API key\"}", 403)
    }
  }
}

fn score_to_json(score: scores.Score) -> json.Json {
  json.object([
    #("player_name", json.string(score.player_name)),
    #("score", json.int(score.score)),
    #("created_at", json.int(score.created_at)),
  ])
}

fn validate_player_name(name: String) -> Result(String, String) {
  let valid_chars = [
    "A",
    "B",
    "C",
    "D",
    "E",
    "F",
    "G",
    "H",
    "I",
    "J",
    "K",
    "L",
    "M",
    "N",
    "O",
    "P",
    "Q",
    "R",
    "S",
    "T",
    "U",
    "V",
    "W",
    "X",
    "Y",
    "Z",
    "Å",
    "Ä",
    "Ö",
  ]

  case string.length(name) {
    3 -> {
      let uppercase_name = string.uppercase(name)
      case
        string.to_graphemes(uppercase_name)
        |> list.all(fn(c) { list.contains(valid_chars, c) })
      {
        True -> Ok(uppercase_name)
        // Return the cleaned up name
        False -> Error("Player name must be 3 letters (A-Z)")
      }
    }
    _ -> Error("Player name must be exactly 3 letters")
  }
}

fn list_scores(ctx: web.Context, game_id: String) -> Response {
  case scores.get_top_scores(ctx.db, game_id, 100) {
    Ok(score_list) -> {
      let response_json =
        json.object([#("scores", json.array(score_list, score_to_json))])
        |> json.to_string

      wisp.json_response(response_json, 200)
    }
    Error(_) -> {
      wisp.internal_server_error()
      |> wisp.json_body("{\"error\": \"Failed to retrieve scores\"}")
    }
  }
}
