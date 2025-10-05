import cors_builder as cors
import gleam/http
import gleam/list
import gleam/option.{type Option, None, Some}
import gleam/result
import gleam/string
import sqlight
import wisp

pub type Context {
  Context(
    db: sqlight.Connection,
    api_key: Option(String),
    static_directory: String,
  )
}

pub fn middleware(
  req: wisp.Request,
  ctx: Context,
  handle_request: fn(wisp.Request, Context) -> wisp.Response,
) -> wisp.Response {
  let req = wisp.method_override(req)
  use <- wisp.log_request(req)
  use <- wisp.rescue_crashes
  use req <- wisp.handle_head(req)
  use req <- wisp.csrf_known_header_protection(req)
  use <- wisp.serve_static(req, under: "/static", from: ctx.static_directory)
  use req <- cors.wisp_middleware(req, cors())

  let api_key = extract_api_key_from_header(req)
  let updated_ctx =
    Context(
      db: ctx.db,
      api_key: api_key,
      static_directory: ctx.static_directory,
    )

  handle_request(req, updated_ctx)
}

fn extract_api_key_from_header(req: wisp.Request) -> Option(String) {
  // Try X-API-Key first, then Authorization Bearer
  case get_header_value(req.headers, "x-api-key") {
    Some(api_key) -> Some(api_key)
    None -> {
      case get_header_value(req.headers, "authorization") {
        Some(auth_header) -> {
          case string.starts_with(auth_header, "Bearer ") {
            True -> {
              let api_key = string.drop_start(auth_header, 7)
              // remove 'Bearer '
              Some(api_key)
            }
            False -> None
          }
        }
        None -> None
      }
    }
  }
}

fn get_header_value(
  headers: List(#(String, String)),
  header_name: String,
) -> Option(String) {
  headers
  |> list.find(fn(header) {
    let #(name, _) = header
    string.lowercase(name) == string.lowercase(header_name)
  })
  |> result.map(fn(header) {
    let #(_, value) = header
    value
  })
  |> option.from_result()
}

fn cors() {
  cors.new()
  |> cors.allow_all_origins()
  |> cors.allow_method(http.Get)
  |> cors.allow_method(http.Post)
  |> cors.allow_header("Content-Type")
  |> cors.allow_header("X-API-Key")
  |> cors.allow_header("Authorization")
  |> cors.max_age(86_400)
}
