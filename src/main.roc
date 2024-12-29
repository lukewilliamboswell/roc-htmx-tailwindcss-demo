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
    basePath : Str,
    dbPath : Str,
}

init! : {} => Result Model [Exit I32 Str]_
init! = \_ ->

    basePath = Env.var! "STATIC_FILES" |> Result.mapErr? UnableToReadStaticFiles

    dbPath = Env.var! "DB_PATH" |> Result.mapErr? UnableToReadDbPATH

    Ok {
        basePath,
        dbPath,
    }

respond! : Request, Model => Result Response _
respond! = \req, model ->
    when handleReq! req model is
        Ok response -> Ok response
        Err err -> (handleAppErr req) err

handleAppErr : Request -> (_ => Result Response _)
handleAppErr = \req -> \err ->
    when err is
        URLNotFound url ->
            methodStr = Inspect.toStr req.method
            errMsg = Str.joinWith ["404 NotFound" |> ANSI.color { fg: Standard Yellow }, methodStr, url] " "
            Stderr.line!? errMsg

            Views.Pages.error404 {}
            |> Views.Layout.normal
            |> Helpers.respondTemplate! 404 []

        # InvalidSessionCookie ->
        #    Views.Pages.error404 {}
        #    |> Views.Layout.normal
        #    |> Helpers.respondTemplate! 404 []
        Unauthorized ->
            Views.Pages.error401 {}
            |> Views.Layout.normal
            |> Helpers.respondTemplate! 401 []

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
            errMsg = Str.joinWith ["500 Server Error" |> ANSI.color { fg: Standard Red }, Inspect.toStr err] " "
            Stderr.line!? errMsg

            Views.Pages.error500 {}
            |> Views.Layout.normal
            |> Helpers.respondTemplate! 500 []

handleReq! : Request, Model => Result Response _
handleReq! = \req, model ->

    logRequest!? req # Log the date, time, method, and url to stdout

    urlSegments =
        req.uri
        |> Url.from_str
        |> Url.path
        |> Str.splitOn "/"
        |> List.dropFirst 1

    queryParams =
        req.uri
        |> Helpers.parseQueryParams
        |> Result.withDefault (Dict.empty {})

    partial =
        queryParams
        |> Dict.get "partial"
        |> Result.map \val -> if val == "true" then Bool.true else Bool.false
        |> Result.withDefault Bool.false

    getStaticFile! = staticFile model.basePath

    when (req.method, urlSegments) is
        (GET, ["www", .. as rest]) -> getStaticFile! (Str.joinWith rest "/")
        (GET, ["favicon.ico"]) -> getStaticFile! "favicon.ico"
        (GET, ["android-chrome-192x192.png"]) -> getStaticFile! "android-chrome-192x192.png"
        (GET, ["android-chrome-512x512.png"]) -> getStaticFile! "android-chrome-512x512.png"
        (GET, ["signin"]) ->
            Views.Pages.pageSignIn {}
            |> Views.Layout.normal
            |> Helpers.respondTemplate! 200 []

        (GET, ["signup"]) ->
            Views.Pages.pageSignUp {}
            |> Views.Layout.normal
            |> Helpers.respondTemplate! 200 []

        (GET, ["forgotpassword"]) ->
            Views.Pages.pageForgotPassword {}
            |> Views.Layout.normal
            |> Helpers.respondTemplate! 200 []

        (GET, ["resetpassword"]) ->
            Views.Pages.pageResetPassword {}
            |> Views.Layout.normal
            |> Helpers.respondTemplate! 200 []

        (GET, ["profilelock"]) ->
            Views.Pages.pageProfileLock {}
            |> Views.Layout.normal
            |> Helpers.respondTemplate! 200 []

        (GET, [""]) | (_, ["products", ..]) ->
            Controllers.Product.handleRoutes! {
                req,
                urlSegments: List.dropFirst urlSegments 1,
                dbPath: model.dbPath,
            }

        (_, ["users", ..]) ->
            Controllers.User.handleRoutes! {
                req,
                urlSegments: List.dropFirst urlSegments 1,
                dbPath: model.dbPath,
            }

        (_, ["settings", ..]) ->
            view = Views.Pages.pageSettings {}

            if partial then
                view
                |> Helpers.respondTemplate! 200 [
                    { name: "HX-Push-Url", value: "/settings" },
                ]
            else
                view
                |> Views.Layout.sidebar
                |> Helpers.respondTemplate! 200 [
                    { name: "HX-Push-Url", value: "/settings" },
                ]

        (GET, ["test404"]) -> Err (URLNotFound "Test404Error")
        (GET, ["test500"]) -> Err Test500Error
        _ -> Err (URLNotFound req.uri)

staticFile : Str -> (Str => Result Response _)
staticFile = \basePath -> \relPath ->

    path = "$(basePath)/$(relPath)"

    body =
        File.read_bytes! path
        |> Result.mapErr? \err -> ErrGettingStaticFile path (Inspect.toStr err)

    bytesRead = List.len body

    Helpers.info!? "Read $(Num.toStr bytesRead) bytes for static file $(path)"

    contentTypeHeader =
        if Str.endsWith relPath ".svg" then
            { name: "Content-Type", value: "image/svg+xml" }
        else if Str.endsWith relPath ".css" then
            { name: "Content-Type", value: "text/css" }
        else if Str.endsWith relPath ".js" then
            { name: "Content-Type", value: "application/javascript" }
        else if Str.endsWith relPath ".ico" then
            { name: "Content-Type", value: "image/x-icon" }
        else if Str.endsWith relPath ".png" then
            { name: "Content-Type", value: "image/png" }
        else if Str.endsWith relPath ".jpg" then
            { name: "Content-Type", value: "image/jpeg" }
        else if Str.endsWith relPath ".jpeg" then
            { name: "Content-Type", value: "image/jpeg" }
        else if Str.endsWith relPath ".gif" then
            { name: "Content-Type", value: "image/gif" }
        else
            { name: "Content-Type", value: "application/octet-stream" }

    Ok {
        status: 200,
        headers: [
            { name: "Cache-Control", value: "max-age=3600" },
            contentTypeHeader,
        ],
        body,
    }

logRequest! : Request => Result {} _
logRequest! = \req ->
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
