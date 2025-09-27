import gleam/http.{Get}
import handlers/games.{create_game_handler, games_handler}
import handlers/scores.{scores_handler}
import web
import wisp.{type Request, type Response}

pub fn handle_request(req: Request, ctx: web.Context) -> Response {
  case wisp.path_segments(req) {
    [] -> home_page(req)
    ["api", "v1", "games"] -> create_game_handler(req, ctx)
    ["api", "v1", "games", game_id] -> games_handler(req, ctx, game_id)
    ["api", "v1", "games", game_id, "scores"] ->
      scores_handler(req, ctx, game_id)
    _ -> wisp.not_found()
  }
}

fn home_page(req: Request) -> Response {
  use <- wisp.require_method(req, Get)

  let html = "<h1>Skryt API</h1>"
  wisp.ok()
  |> wisp.html_body(html)
}
