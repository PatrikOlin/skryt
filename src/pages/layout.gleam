import lustre/attribute as attr
import lustre/element.{type Element}
import lustre/element/html

pub fn page(title: String, content: Element(a)) -> Element(a) {
  html.html([attr.attribute("lang", "en")], [
    html.head([], [
      html.meta([attr.attribute("charset", "utf-8")]),
      html.title([], title),
      html.meta([
        attr.attribute("name", "viewport"),
        attr.attribute("content", "width=device-width, initial-scale=1"),
      ]),
      html.link([
        attr.attribute("rel", "stylesheet"),
        attr.attribute("href", "/static/css/app.css"),
      ]),
    ]),
    html.body([], [
      html.div([attr.class("fixed left-0 top-0 right-0 bottom-0")], [
        html.div([attr.class("relative -z-10 h-full w-full bg-slate-950")], [
          html.div(
            [
              attr.class(
                "absolute -z-10 bottom-0 left-0 right-0 top-0 bg-[linear-gradient(to_right,#4f4f4f2e_1px,transparent_1px),linear-gradient(to_bottom,#4f4f4f2e_1px,transparent_1px)] bg-[size:14px_24px] [mask-image:radial-gradient(ellipse_60%_50%_at_50%_0%,#000_70%,transparent_100%)]",
              ),
            ],
            [],
          ),
        ]),
      ]),
      html.main([attr.class("relative z-1")], [content]),
    ]),
  ])
}
