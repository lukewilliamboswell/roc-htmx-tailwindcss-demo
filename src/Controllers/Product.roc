module [handle_routes!]

import web.Http exposing [Request, Response]
import Sql.Product
import Views.Layout
import Views.Pages
import Helpers

handle_routes! :
    {
        req : Request,
        url_segments : List Str,
        db_path : Str,
    }
    => Result Response _
handle_routes! = \{ req, url_segments, db_path } ->

    query_params =
        req.uri
        |> Helpers.parse_query_params
        |> Result.withDefault (Dict.empty {})

    partial =
        query_params
        |> Dict.get "partial"
        |> Result.map \val -> if val == "true" then Bool.true else Bool.false
        |> Result.withDefault Bool.false

    when (req.method, url_segments) is
        (GET, []) ->
            products = Sql.Product.list!? { db_path }

            view = Views.Pages.pageProducts {
                products,
            }

            if partial then
                view
                |> Helpers.respond_template! 200 [
                    { name: "HX-Push-Url", value: "/products" },
                ]
            else
                view
                |> Views.Layout.sidebar
                |> Helpers.respond_template! 200 [
                    { name: "HX-Push-Url", value: "/products" },
                ]

        _ -> Err (NotHandled req)
