import gleam/http.{Get}
import handlers/games.{create_game_handler, games_handler}
import handlers/pages.{game_page_handler}
import handlers/scores.{scores_handler}
import lustre/element
import pages/home
import web
import wisp.{type Request, type Response}

pub fn handle_request(req: Request, ctx: web.Context) -> Response {
  case wisp.path_segments(req) {
    [] -> home_page(req)
    ["games", slug] -> game_page_handler(req, ctx, slug)
    ["api", "v1", ..rest] -> handle_api_v1(req, ctx, rest)
    _ -> wisp.not_found()
  }
}

fn handle_api_v1(
  req: Request,
  ctx: web.Context,
  segments: List(String),
) -> Response {
  case segments {
    ["games"] -> create_game_handler(req, ctx)
    ["games", game_id] -> games_handler(req, ctx, game_id)
    ["games", game_id, "scores"] -> scores_handler(req, ctx, game_id)
    _ -> wisp.not_found()
  }
}

fn home_page(req: Request) -> Response {
  use <- wisp.require_method(req, Get)

  let html =
    home.view()
    |> element.to_document_string()

  wisp.ok()
  |> wisp.html_body(html)
}
