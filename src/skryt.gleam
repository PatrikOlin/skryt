import database/connection
import gleam/erlang/process
import gleam/option.{None}
import gleam/string
import mist
import router
import web
import wisp
import wisp/wisp_mist

pub fn main() {
  wisp.configure_logger()

  let secret_key = wisp.random_string(64)

  case connection.setup() {
    Ok(db) -> {
      // create context with db connection
      let context = web.Context(db: db, api_key: None)

      // partially apply the context to the router
      let handler = fn(req) {
        web.middleware(req, context, router.handle_request)
      }

      let assert Ok(_) =
        handler
        |> wisp_mist.handler(secret_key)
        |> mist.new
        |> mist.bind("0.0.0.0")
        |> mist.port(8000)
        |> mist.start

      process.sleep_forever()
    }
    Error(e) -> {
      wisp.log_critical("Failed to set up database: " <> string.inspect(e))
    }
  }
}
