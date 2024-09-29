module [handleRoutes]

import web.Http exposing [Request, Response]
import Sql.Product
import Views.Layout
import Views.Pages
import Helpers exposing [respondTemplate, parseQueryParams]

handleRoutes :
    {
        req : Request,
        urlSegments : List Str,
        dbPath : Str,
    }
    -> Task Response _
handleRoutes = \{ req, urlSegments, dbPath } ->

    queryParams =
        req.url
        |> parseQueryParams
        |> Result.withDefault (Dict.empty {})

    partial =
        queryParams
        |> Dict.get "partial"
        |> Result.map \val -> if val == "true" then Bool.true else Bool.false
        |> Result.withDefault Bool.false

    when (req.method, urlSegments) is
        (Get, []) ->
            products = Sql.Product.list! { dbPath }

            view = Views.Pages.pageProducts {
                products,
            }

            if partial then
                view
                |> respondTemplate 200 [
                    { name: "HX-Push-Url", value: "/products" },
                ]
            else
                view
                |> Views.Layout.sidebar
                |> respondTemplate 200 [
                    { name: "HX-Push-Url", value: "/products" },
                ]

        _ -> Task.err (NotHandled req)
