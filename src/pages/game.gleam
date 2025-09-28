import database/games
import database/scores
import gleam/int
import gleam/list
import lustre/attribute as attr
import lustre/element.{type Element}
import lustre/element/html
import pages/layout

pub fn view(game: games.Game, scores: List(scores.Score)) -> Element(a) {
  let content =
    html.div([attr.class("container mx-auto px-4 py-8")], [
      game_header(game),
      scores_section(scores),
    ])

  layout.page(game.name <> " - Leaderboard", content)
}

fn game_header(game: games.Game) -> Element(a) {
  html.div([attr.class("mb-8")], [
    html.h1(
      [attr.class("text-4xl font-heading font-bold text-center text-primary")],
      [html.text(game.name)],
    ),
    html.p([attr.class("text-center text-gray-400 mt-2")], [
      html.text("High score leaderboard"),
    ]),
  ])
}

fn scores_section(scores: List(scores.Score)) -> Element(a) {
  case scores {
    [] -> no_scores_message()
    _ -> scores_table(scores)
  }
}

fn no_scores_message() -> Element(a) {
  html.div([attr.class("text-center py-16")], [
    html.p([attr.class("text-xl text-gray-500")], [
      html.text("No scores yet. Be the first to submit a score!"),
    ]),
  ])
}

fn scores_table(scores: List(scores.Score)) -> Element(a) {
  html.div([attr.class("max-w-2xl mx-auto")], [
    html.table(
      [attr.class("w-full bg-white shadow-lg rounded-lg overflow-hidden")],
      [table_header(), html.tbody([], list.index_map(scores, score_row))],
    ),
  ])
}

fn table_header() -> Element(a) {
  html.thead([attr.class("bg-gray-50")], [
    html.tr([], [
      html.th([attr.class("text-left text-xs px-6 py-3 text-gray-500")], [
        html.text("Rank"),
      ]),
      html.th([attr.class("text-left text-xs px-6 py-3 text-gray-500")], [
        html.text("Player"),
      ]),
      html.th([attr.class("text-left text-xs px-6 py-3 text-gray-500")], [
        html.text("Score"),
      ]),
    ]),
  ])
}

fn score_row(score: scores.Score, index: Int) -> Element(a) {
  let rank = index + 1
  let row_class = case rank {
    1 -> "bg-yellow-50 border-l-4 border-yellow-400"
    2 -> "bg-gray-50 border-l-4 border-gray-400"
    3 -> "bg-orange-50 border-l-4 border-orange-400"
    _ -> "bg-white hover:bg-grey-50"
  }

  html.tr([attr.class(row_class)], [
    html.td(
      [
        attr.class(
          "px-6 py-4 whitespace-nowrap text-sm font-medium text-gray-900",
        ),
      ],
      [html.text(int.to_string(rank))],
    ),
    html.td(
      [
        attr.class(
          "px-6 py-4 whitespace-nowrap text-sm font-mono font-bold text-gray-900",
        ),
      ],
      [html.text(score.player_name)],
    ),
    html.td([attr.class("px-6 py-4 whitespace-nowrap text-sm text-gray-900")], [
      html.text(int.to_string(score.score)),
    ]),
  ])
}
