import database/games
import database/scores
import gleam/http.{Get}
import gleam/int
import gleam/io
import gleam/list
import lustre/element
import pages/game as pages_game
import web
import wisp.{type Request, type Response}

pub fn game_page_handler(
  req: Request,
  ctx: web.Context,
  slug: String,
) -> Response {
  use <- wisp.require_method(req, Get)

  case games.get_game_by_slug(ctx.db, slug) {
    Ok(game) -> {
      case scores.get_top_scores(ctx.db, game.id, 100) {
        Ok(game_scores) -> render_game_page(game, game_scores)
        Error(_) -> {
          io.println(
            "Failed to get scores for game "
            <> game.slug
            <> ", will render page without them.",
          )
          render_game_page(game, [])
        }
      }
    }
    Error(games.GameNotFound) -> wisp.not_found()
    Error(_) -> wisp.internal_server_error()
  }
}

fn render_game_page(game: games.Game, scores: List(scores.Score)) {
  io.println(
    "Rendering game page for "
    <> game.slug
    <> " with "
    <> int.to_string(list.length(scores))
    <> " scores.",
  )
  let html =
    pages_game.view(game, scores)
    |> element.to_document_string()

  wisp.ok()
  |> wisp.html_body(html)
}
