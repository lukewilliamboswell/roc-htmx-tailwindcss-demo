app [Model, init!, respond!] {
    web: platform "https://github.com/roc-lang/basic-webserver/releases/download/0.11.0/yWHkcVUt_WydE1VswxKFmKFM5Tlu9uMn6ctPVYaas7I.tar.br",
    html: "https://github.com/Hasnep/roc-html/releases/download/v0.6.0/IOyNfA4U_bCVBihrs95US9Tf5PGAWh3qvrBN4DRbK5c.tar.br",
    ansi: "https://github.com/lukewilliamboswell/roc-ansi/releases/download/0.7.0/NmbsrdwKIOb1DtUIV7L_AhCvTx7nhfaW3KkOpT7VUZg.tar.br",
    json: "https://github.com/lukewilliamboswell/roc-json/releases/download/0.11.0/z45Wzc-J39TLNweQUoLw3IGZtkQiEN3lTBv3BXErRjQ.tar.br",
}

import web.Stdout
import web.Stderr
import web.Http exposing [Request, Response]
import web.Utc
import web.File
import web.Url
import web.Env
import ansi.ANSI
import Helpers
import Views.Pages
import Views.Layout
import Controllers.Product
import Controllers.User

Model : {
    base_path : Str,
    db_path : Str,
}

init! : {} => Result Model [Exit I32 Str]_
init! = \_ ->

    base_path = Env.var! "STATIC_FILES" |> Result.mapErr? UnableToReadStaticFiles

    db_path = Env.var! "DB_PATH" |> Result.mapErr? UnableToReadDbPATH

    Ok {
        base_path,
        db_path,
    }

respond! : Request, Model => Result Response _
respond! = \req, model ->
    when handle_req! req model is
        Ok response -> Ok response
        Err err -> (handle_app_err req) err

handle_app_err : Request -> (_ => Result Response _)
handle_app_err = \req -> \err ->
    when err is
        URLNotFound url ->
            method_str = Inspect.toStr req.method
            err_msg = Str.joinWith ["404 NotFound" |> ANSI.color { fg: Standard Yellow }, method_str, url] " "
            Stderr.line!? err_msg

            Views.Pages.error404 {}
            |> Views.Layout.normal
            |> Helpers.respond_template! 404 []

        # InvalidSessionCookie ->
        #    Views.Pages.error404 {}
        #    |> Views.Layout.normal
        #    |> Helpers.respondTemplate! 404 []
        Unauthorized ->
            Views.Pages.error401 {}
            |> Views.Layout.normal
            |> Helpers.respond_template! 401 []

        # NewSession sessionId ->
        #    # Redirect to the same URL with the new session ID
        #    Ok {
        #        status: 303,
        #        headers: [
        #            { name: "Set-Cookie", value: "sessionId=$(Num.toStr sessionId)" },
        #            { name: "Location", value: req.url },
        #        ],
        #        body: [],
        #    }
        _ ->
            err_msg = Str.joinWith ["500 Server Error" |> ANSI.color { fg: Standard Red }, Inspect.toStr err] " "
            Stderr.line!? err_msg

            Views.Pages.error500 {}
            |> Views.Layout.normal
            |> Helpers.respond_template! 500 []

handle_req! : Request, Model => Result Response _
handle_req! = \req, model ->

    log_request!? req # Log the date, time, method, and url to stdout

    url_segments =
        req.uri
        |> Url.from_str
        |> Url.path
        |> Str.splitOn "/"
        |> List.dropFirst 1

    query_params =
        req.uri
        |> Helpers.parse_query_params
        |> Result.withDefault (Dict.empty {})

    partial =
        query_params
        |> Dict.get "partial"
        |> Result.map \val -> if val == "true" then Bool.true else Bool.false
        |> Result.withDefault Bool.false

    get_static_file! = static_file model.base_path

    when (req.method, url_segments) is
        (GET, ["www", .. as rest]) -> get_static_file! (Str.joinWith rest "/")
        (GET, ["favicon.ico"]) -> get_static_file! "favicon.ico"
        (GET, ["android-chrome-192x192.png"]) -> get_static_file! "android-chrome-192x192.png"
        (GET, ["android-chrome-512x512.png"]) -> get_static_file! "android-chrome-512x512.png"
        (GET, ["signin"]) ->
            Views.Pages.pageSignIn {}
            |> Views.Layout.normal
            |> Helpers.respond_template! 200 []

        (GET, ["signup"]) ->
            Views.Pages.pageSignUp {}
            |> Views.Layout.normal
            |> Helpers.respond_template! 200 []

        (GET, ["forgotpassword"]) ->
            Views.Pages.pageForgotPassword {}
            |> Views.Layout.normal
            |> Helpers.respond_template! 200 []

        (GET, ["resetpassword"]) ->
            Views.Pages.pageResetPassword {}
            |> Views.Layout.normal
            |> Helpers.respond_template! 200 []

        (GET, ["profilelock"]) ->
            Views.Pages.pageProfileLock {}
            |> Views.Layout.normal
            |> Helpers.respond_template! 200 []

        (GET, [""]) | (_, ["products", ..]) ->
            Controllers.Product.handle_routes! {
                req,
                url_segments: List.dropFirst url_segments 1,
                db_path: model.db_path,
            }

        (_, ["users", ..]) ->
            Controllers.User.handle_routes! {
                req,
                url_segments: List.dropFirst url_segments 1,
                db_path: model.db_path,
            }

        (_, ["settings", ..]) ->
            view = Views.Pages.pageSettings {}

            if partial then
                view
                |> Helpers.respond_template! 200 [
                    { name: "HX-Push-Url", value: "/settings" },
                ]
            else
                view
                |> Views.Layout.sidebar
                |> Helpers.respond_template! 200 [
                    { name: "HX-Push-Url", value: "/settings" },
                ]

        (GET, ["test404"]) -> Err (URLNotFound "Test404Error")
        (GET, ["test500"]) -> Err Test500Error
        _ -> Err (URLNotFound req.uri)

static_file : Str -> (Str => Result Response _)
static_file = \base_path -> \rel_path ->

    path = "$(base_path)/$(rel_path)"

    body =
        File.read_bytes! path
        |> Result.mapErr? \err -> ErrGettingStaticFile path (Inspect.toStr err)

    bytes_read = List.len body

    Helpers.info!? "Read $(Num.toStr bytes_read) bytes for static file $(path)"

    content_type_header =
        if Str.endsWith rel_path ".svg" then
            { name: "Content-Type", value: "image/svg+xml" }
        else if Str.endsWith rel_path ".css" then
            { name: "Content-Type", value: "text/css" }
        else if Str.endsWith rel_path ".js" then
            { name: "Content-Type", value: "application/javascript" }
        else if Str.endsWith rel_path ".ico" then
            { name: "Content-Type", value: "image/x-icon" }
        else if Str.endsWith rel_path ".png" then
            { name: "Content-Type", value: "image/png" }
        else if Str.endsWith rel_path ".jpg" then
            { name: "Content-Type", value: "image/jpeg" }
        else if Str.endsWith rel_path ".jpeg" then
            { name: "Content-Type", value: "image/jpeg" }
        else if Str.endsWith rel_path ".gif" then
            { name: "Content-Type", value: "image/gif" }
        else
            { name: "Content-Type", value: "application/octet-stream" }

    Ok {
        status: 200,
        headers: [
            { name: "Cache-Control", value: "max-age=3600" },
            content_type_header,
        ],
        body,
    }

log_request! : Request => Result {} _
log_request! = \req ->
    date = Utc.to_iso_8601 (Utc.now! {})
    method = Inspect.toStr req.method
    url = req.uri
    # body can be large, don't log it
    # body = req.body |> Str.fromUtf8 |> Result.withDefault "<invalid utf8 body>"
    Stdout.line! "$(date) $(method) $(url)"

# getSession : Request, Str -> Task Session _
# getSession = \req, dbPath ->
#    Sql.Session.parse req
#        |> Task.fromResult
#        |> Task.await \id -> Sql.Session.get id dbPath
#        |> Task.onErr \err ->
#            if err == SessionNotFound || err == NoSessionCookie then
#                id = Sql.Session.new! dbPath

#                Err (NewSession id)
#            else
#                Err err
