module [
    respond_redirect!,
    respond_html!,
    decode_form_values,
    parse_query_params,
    query_params_to_str,
    parse_paged_params,
    replace_query_params,
    respond_template!,
    decode_multi_part_form_boundary,
    info!,
]

import web.Stdout
import web.Http exposing [Response]
import web.MultipartFormData exposing [parse_form_url_encoded]
import html.Html

respond_redirect! : Str => Result Response []_
respond_redirect! = \next ->
    Ok {
        status: 303,
        headers: [
            { name: "Location", value: next },
        ],
        body: [],
    }

respond_html! : Html.Node, List { name : Str, value : Str } => Result Response []_
respond_html! = \node, other_headers ->
    Ok {
        status: 200,
        headers: [
            { name: "Content-Type", value: "text/html; charset=utf-8" },
        ]
        |> List.concat other_headers,
        body: Str.toUtf8 (Html.render node),
    }

decode_form_values : List U8 -> Result (Dict Str Str) _
decode_form_values = \body ->
    parse_form_url_encoded body
    |> Result.mapErr \BadUtf8 -> BadRequest InvalidFormEncoding

parse_query_params : Str -> Result (Dict Str Str) _
parse_query_params = \url ->
    when Str.splitOn url "?" is
        [_, query_part] -> query_part |> Str.toUtf8 |> parse_form_url_encoded
        parts -> Err (InvalidQuery (Inspect.toStr parts))

query_params_to_str : Dict Str Str -> Str
query_params_to_str = \params ->
    Dict.toList params
    |> List.map \(k, v) -> "$(k)=$(v)"
    |> Str.joinWith "&"

expect
    "localhost:8000?port=8000&name=Luke"
    |> parse_query_params
    |> Result.map query_params_to_str
    ==
    Ok "port=8000&name=Luke"

parse_paged_params : Dict Str Str -> Result { page : I64, items : I64 } _
parse_paged_params = \query_params ->

    maybe_page = query_params |> Dict.get "page" |> Result.try Str.toI64
    maybe_count = query_params |> Dict.get "items" |> Result.try Str.toI64

    when (maybe_page, maybe_count) is
        (Ok page, Ok items) if page >= 1 && items > 0 -> Ok { page, items }
        _ -> Err InvalidPagedParams

expect
    "/bigTask?page=22&items=33"
    |> parse_query_params
    |> Result.try parse_paged_params
    ==
    Ok { page: 22, items: 33 }

expect
    "/bigTask?page=0&count=33"
    |> parse_query_params
    |> Result.try parse_paged_params
    ==
    Err InvalidPagedParams

expect
    "/bigTask"
    |> parse_query_params
    |> Result.try parse_paged_params
    ==
    Err (InvalidQuery "[\"/bigTask\"]")

replace_query_params : { url : Str, params : Dict Str Str } -> Str
replace_query_params = \{ url, params } ->
    when Str.splitFirst url "?" is
        Ok { before } if Dict.isEmpty params -> "$(before)"
        Err NotFound if Dict.isEmpty params -> "$(url)"
        Ok { before } -> "$(before)?$(query_params_to_str params)"
        Err NotFound -> "$(url)?$(query_params_to_str params)"

expect replace_query_params { url: "/bigTask", params: Dict.empty {} } == "/bigTask"
expect replace_query_params { url: "/bigTask?items=33", params: Dict.empty {} } == "/bigTask"
expect replace_query_params { url: "/bigTask?items=33", params: Dict.fromList [("page", "22")] } == "/bigTask?page=22"

respond_template! : Str, U16, _ => Result Response []_
respond_template! = \html, status, headers ->
    Ok {
        status,
        headers: List.concat headers [
            { name: "Content-Type", value: "text/html; charset=utf-8" },
        ],
        body: html |> Str.toUtf8,
    }

decode_multi_part_form_boundary : List { name : Str, value : Str } -> Result (List U8) _
decode_multi_part_form_boundary = \headers ->
    headers
    |> List.keepIf \{ name } -> name == "Content-Type" || name == "content-type"
    |> List.first
    |> Result.mapErr \_ -> ExpectedContentTypeHeader headers
    |> Result.try \{ value } ->
        when Str.splitLast value "=" is
            Ok { after } -> Ok (Str.toUtf8 after)
            Err err -> Err (InvalidContentTypeHeader err value)

info! : Str => Result {} _
info! = \msg ->
    Stdout.line! "\u(001b)[34mINFO:\u(001b)[0m $(msg)"
