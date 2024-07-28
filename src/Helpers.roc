module [
    respondRedirect,
    respondHtml,
    decodeFormValues,
    parseQueryParams,
    queryParamsToStr,
    parsePagedParams,
    replaceQueryParams,
    respondTemplate,
    decodeMultiPartFormBoundary,
    info,
]

import pf.Task exposing [Task]
import pf.Stdout
import pf.Http exposing [Response]
import html.Html

respondRedirect : Str -> Task Response []_
respondRedirect = \next ->
    Task.ok {
        status: 303,
        headers: [
            { name: "Location", value: next },
        ],
        body: [],
    }

respondHtml : Html.Node, List { name : Str, value : Str } -> Task Response []_
respondHtml = \node, otherHeaders ->
    Task.ok {
        status: 200,
        headers: [
            { name: "Content-Type", value: "text/html; charset=utf-8" },
        ]
        |> List.concat otherHeaders,
        body: Str.toUtf8 (Html.render node),
    }

decodeFormValues : List U8 -> Task (Dict Str Str) _
decodeFormValues = \body ->
    Http.parseFormUrlEncoded body
    |> Result.mapErr \BadUtf8 -> BadRequest InvalidFormEncoding
    |> Task.fromResult

parseQueryParams : Str -> Result (Dict Str Str) _
parseQueryParams = \url ->
    when Str.split url "?" is
        [_, queryPart] -> queryPart |> Str.toUtf8 |> Http.parseFormUrlEncoded
        parts -> Err (InvalidQuery (Inspect.toStr parts))

queryParamsToStr : Dict Str Str -> Str
queryParamsToStr = \params ->
    Dict.toList params
    |> List.map \(k, v) -> "$(k)=$(v)"
    |> Str.joinWith "&"

expect
    "localhost:8000?port=8000&name=Luke"
    |> parseQueryParams
    |> Result.map queryParamsToStr
    ==
    Ok "port=8000&name=Luke"

parsePagedParams : Dict Str Str -> Result { page : I64, items : I64 } _
parsePagedParams = \queryParams ->

    maybePage = queryParams |> Dict.get "page" |> Result.try Str.toI64
    maybeCount = queryParams |> Dict.get "items" |> Result.try Str.toI64

    when (maybePage, maybeCount) is
        (Ok page, Ok items) if page >= 1 && items > 0 -> Ok { page, items }
        _ -> Err InvalidPagedParams

expect
    "/bigTask?page=22&items=33"
    |> parseQueryParams
    |> Result.try parsePagedParams
    ==
    Ok { page: 22, items: 33 }

expect
    "/bigTask?page=0&count=33"
    |> parseQueryParams
    |> Result.try parsePagedParams
    ==
    Err InvalidPagedParams

expect
    "/bigTask"
    |> parseQueryParams
    |> Result.try parsePagedParams
    ==
    Err (InvalidQuery "[\"/bigTask\"]")

replaceQueryParams : { url : Str, params : Dict Str Str } -> Str
replaceQueryParams = \{ url, params } ->
    when Str.splitFirst url "?" is
        Ok { before } if Dict.isEmpty params -> "$(before)"
        Err NotFound if Dict.isEmpty params -> "$(url)"
        Ok { before } -> "$(before)?$(queryParamsToStr params)"
        Err NotFound -> "$(url)?$(queryParamsToStr params)"

expect replaceQueryParams { url: "/bigTask", params: Dict.empty {} } == "/bigTask"
expect replaceQueryParams { url: "/bigTask?items=33", params: Dict.empty {} } == "/bigTask"
expect replaceQueryParams { url: "/bigTask?items=33", params: Dict.fromList [("page", "22")] } == "/bigTask?page=22"

respondTemplate : Str, U16, _ -> Task Response []_
respondTemplate = \html, status, headers ->
    Task.ok {
        status,
        headers: List.concat headers [
            { name: "Content-Type", value: "text/html; charset=utf-8" },
        ],
        body: html |> Str.toUtf8,
    }

decodeMultiPartFormBoundary : List { name : Str, value : Str } -> Result (List U8) _
decodeMultiPartFormBoundary = \headers ->
    headers
    |> List.keepIf \{ name } -> name == "Content-Type" || name == "content-type"
    |> List.first
    |> Result.mapErr \_ -> ExpectedContentTypeHeader headers
    |> Result.try \{ value } ->
        when Str.splitLast value "=" is
            Ok { after } -> Ok (Str.toUtf8 after)
            Err err -> Err (InvalidContentTypeHeader err value)

info : Str -> Task {} _
info = \msg ->
    Stdout.line! "\u(001b)[34mINFO:\u(001b)[0m $(msg)"
