import lustre/attribute as attr
import lustre/element.{type Element}
import lustre/element/html
import pages/layout

pub fn view() -> Element(a) {
  let content =
    html.div([], [
      html.h1(
        [
          attr.class(
            "text-3xl mt-12 font-bold font-heading text-primary text-center",
          ),
        ],
        [
          html.text("Skryt High Score API"),
        ],
      ),
      html.p([], [
        html.text(
          "Welcome to Skryt! This is a simple high score API service for your games.",
        ),
      ]),
    ])

  layout.page("Skryt API", content)
}
