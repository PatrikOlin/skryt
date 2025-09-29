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
    html.p([attr.class("text-center text-xl text-gray-400 mt-2 font-body")], [
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
  html.div([attr.class("max-w-2xl mx-auto font-body text-xl")], [
    html.table(
      [attr.class("w-full bg-slate-800 shadow-lg rounded-lg overflow-hidden")],
      [table_header(), html.tbody([], list.index_map(scores, score_row))],
    ),
  ])
}

fn table_header() -> Element(a) {
  html.thead([attr.class("bg-slate-900")], [
    html.tr([], [
      html.th([attr.class("text-left text-lg px-6 py-3 text-gray-200")], [
        html.text("Rank"),
      ]),
      html.th([attr.class("text-left text-lg px-6 py-3 text-gray-200")], [
        html.text("Player"),
      ]),
      html.th([attr.class("text-left text-lg px-6 py-3 text-gray-200")], [
        html.text("Score"),
      ]),
    ]),
  ])
}

fn score_row(score: scores.Score, index: Int) -> Element(a) {
  let rank = index + 1
  let top_class = case rank {
    1 -> "border-l-4 border-yellow-400"
    2 -> "border-l-4 border-zinc-400"
    3 -> "border-l-4 border-orange-400"
    _ -> ""
  }

  let row_class =
    "odd:bg-gray-700 even:bg-gray-800 hover:bg-gray-900 " <> top_class
  html.tr([attr.class(row_class)], [
    html.td(
      [
        attr.class(
          "px-6 py-4 whitespace-nowrap text-md font-medium text-gray-200",
        ),
      ],
      [html.text(int.to_string(rank))],
    ),
    html.td(
      [
        attr.class(
          "px-6 py-4 whitespace-nowrap text-md font-mono font-bold text-gray-200",
        ),
      ],
      [html.text(score.player_name)],
    ),
    html.td([attr.class("px-6 py-4 whitespace-nowrap text-md text-gray-200")], [
      html.text(int.to_string(score.score)),
    ]),
  ])
}
