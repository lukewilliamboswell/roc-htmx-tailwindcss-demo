module [handleRoutes!]

import web.Http exposing [Request, Response]
import Sql.Product
import Views.Layout
import Views.Pages
import Helpers

handleRoutes! :
    {
        req : Request,
        urlSegments : List Str,
        dbPath : Str,
    }
    => Result Response _
handleRoutes! = \{ req, urlSegments, dbPath } ->

    queryParams =
        req.uri
        |> Helpers.parseQueryParams
        |> Result.withDefault (Dict.empty {})

    partial =
        queryParams
        |> Dict.get "partial"
        |> Result.map \val -> if val == "true" then Bool.true else Bool.false
        |> Result.withDefault Bool.false

    when (req.method, urlSegments) is
        (GET, []) ->
            products = Sql.Product.list!? { dbPath }

            view = Views.Pages.pageProducts {
                products,
            }

            if partial then
                view
                |> Helpers.respondTemplate! 200 [
                    { name: "HX-Push-Url", value: "/products" },
                ]
            else
                view
                |> Views.Layout.sidebar
                |> Helpers.respondTemplate! 200 [
                    { name: "HX-Push-Url", value: "/products" },
                ]

        _ ->  Err (NotHandled req)
