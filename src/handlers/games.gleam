import database/games
import gleam/bit_array
import gleam/crypto
import gleam/dynamic/decode
import gleam/http.{Get, Post}
import gleam/json
import web
import wisp.{type Request, type Response}
import youid/uuid

pub type CreateGameRequest {
  CreateGameRequest(name: String)
}

pub fn games_handler(
  req: Request,
  ctx: web.Context,
  game_id: String,
) -> Response {
  case req.method {
    Get -> get_game(ctx, game_id)
    Post -> create_game(req, ctx)
    _ -> wisp.method_not_allowed([Get, Post])
  }
}

pub fn create_game_handler(req: Request, ctx: web.Context) -> Response {
  case req.method {
    Post -> create_game(req, ctx)
    _ -> wisp.method_not_allowed([Get, Post])
  }
}

fn get_game(_ctx, _game_id) -> Response {
  let body = "[{\"player\": \"ASS\", \"score\": 1000}]"

  wisp.ok()
  |> wisp.json_body(body)
}

fn create_game_decoder() -> decode.Decoder(CreateGameRequest) {
  use name <- decode.field("name", decode.string)
  decode.success(CreateGameRequest(name:))
}

fn create_game(req: Request, ctx: web.Context) -> Response {
  use json <- wisp.require_json(req)

  // Handle JSON decoding separately first
  case decode.run(json, create_game_decoder()) {
    Ok(game_request) -> {
      let game_id = uuid.v4_string()
      let api_key =
        crypto.strong_random_bytes(32)
        |> bit_array.base64_encode(False)

      // Handle database operation separately
      case games.create_game(ctx.db, game_id, game_request.name, api_key) {
        Ok(game) -> {
          let response_json =
            json.object([
              #("id", json.string(game.id)),
              #("name", json.string(game.name)),
              #("api_key", json.string(game.api_key)),
            ])
            |> json.to_string

          wisp.json_response(response_json, 201)
        }
        Error(_) -> {
          wisp.internal_server_error()
          |> wisp.json_body("{\"error\": \"Failed to create game\"}")
        }
      }
    }
    Error(_) -> wisp.unprocessable_content()
  }
}
