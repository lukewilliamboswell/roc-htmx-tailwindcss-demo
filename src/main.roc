app [Model, server] {
    web: platform "https://github.com/roc-lang/basic-webserver/releases/download/0.10.0/BgDDIykwcg51W8HA58FE_BjdzgXVk--ucv6pVb_Adik.tar.br",
    html: "https://github.com/Hasnep/roc-html/releases/download/v0.6.0/IOyNfA4U_bCVBihrs95US9Tf5PGAWh3qvrBN4DRbK5c.tar.br",
    ansi: "https://github.com/lukewilliamboswell/roc-ansi/releases/download/0.7.0/NmbsrdwKIOb1DtUIV7L_AhCvTx7nhfaW3KkOpT7VUZg.tar.br",
    json: "https://github.com/lukewilliamboswell/roc-json/releases/download/0.11.0/z45Wzc-J39TLNweQUoLw3IGZtkQiEN3lTBv3BXErRjQ.tar.br",
}

import web.Stdout
import web.Stderr
import web.Http exposing [Request, Response]
import web.Utc
import web.Path
import web.File
import web.Url
import web.Env
import ansi.ANSI
import Helpers exposing [parseQueryParams, respondTemplate, info]
import Views.Pages
import Views.Layout
import Controllers.Product
import Controllers.User

Model : {
    basePath : Str,
    dbPath : Str,
}

server = { init, respond }

init : Task Model [Exit I32 Str]_
init =

    basePath = Env.var "STATIC_FILES" |> Task.mapErr! UnableToReadStaticFiles

    dbPath = Env.var "DB_PATH" |> Task.mapErr! UnableToReadDbPATH

    Task.ok {
        basePath,
        dbPath,
    }

respond : Request, Model -> Task Response _
respond = \req, model -> Task.onErr (handleReq req model) (handleAppErr req)

handleAppErr : Request -> (_ -> Task Response _)
handleAppErr = \req -> \err ->
        when err is
            URLNotFound url ->
                methodStr = req.method |> Http.methodToStr
                errMsg = Str.joinWith ["404 NotFound" |> ANSI.color { fg: Standard Yellow }, methodStr, url] " "
                Stderr.line! errMsg

                Views.Pages.error404 {}
                |> Views.Layout.normal
                |> respondTemplate 404 []

            # InvalidSessionCookie ->
            #    Views.Pages.error404 {}
            #    |> Views.Layout.normal
            #    |> respondTemplate 404 []
            Unauthorized ->
                Views.Pages.error401 {}
                |> Views.Layout.normal
                |> respondTemplate 401 []

            # NewSession sessionId ->
            #    # Redirect to the same URL with the new session ID
            #    Task.ok {
            #        status: 303,
            #        headers: [
            #            { name: "Set-Cookie", value: "sessionId=$(Num.toStr sessionId)" },
            #            { name: "Location", value: req.url },
            #        ],
            #        body: [],
            #    }
            _ ->
                errMsg = Str.joinWith ["500 Server Error" |> ANSI.color { fg: Standard Red }, Inspect.toStr err] " "
                Stderr.line! errMsg

                Views.Pages.error500 {}
                |> Views.Layout.normal
                |> respondTemplate 500 []

handleReq : Request, Model -> Task Response _
handleReq = \req, model ->

    logRequest! req # Log the date, time, method, and url to stdout

    urlSegments =
        req.url
        |> Url.fromStr
        |> Url.path
        |> Str.splitOn "/"
        |> List.dropFirst 1

    queryParams =
        req.url
        |> parseQueryParams
        |> Result.withDefault (Dict.empty {})

    partial =
        queryParams
        |> Dict.get "partial"
        |> Result.map \val -> if val == "true" then Bool.true else Bool.false
        |> Result.withDefault Bool.false

    getStaticFile = staticFile model.basePath

    dbg urlSegments

    when (req.method, urlSegments) is
        (Get, ["www", .. as rest]) -> getStaticFile (Str.joinWith rest "/")
        (Get, ["favicon.ico"]) -> getStaticFile "favicon.ico"
        (Get, ["android-chrome-192x192.png"]) -> getStaticFile "android-chrome-192x192.png"
        (Get, ["android-chrome-512x512.png"]) -> getStaticFile "android-chrome-512x512.png"
        (Get, ["signin"]) ->
            Views.Pages.pageSignIn {}
            |> Views.Layout.normal
            |> respondTemplate 200 []

        (Get, ["signup"]) ->
            Views.Pages.pageSignUp {}
            |> Views.Layout.normal
            |> respondTemplate 200 []

        (Get, ["forgotpassword"]) ->
            Views.Pages.pageForgotPassword {}
            |> Views.Layout.normal
            |> respondTemplate 200 []

        (Get, ["resetpassword"]) ->
            Views.Pages.pageResetPassword {}
            |> Views.Layout.normal
            |> respondTemplate 200 []

        (Get, ["profilelock"]) ->
            Views.Pages.pageProfileLock {}
            |> Views.Layout.normal
            |> respondTemplate 200 []

        (Get, [""]) | (_, ["products", ..]) ->
            Controllers.Product.handleRoutes {
                req,
                urlSegments: List.dropFirst urlSegments 1,
                dbPath: model.dbPath,
            }

        (_, ["users", ..]) ->
            Controllers.User.handleRoutes {
                req,
                urlSegments: List.dropFirst urlSegments 1,
                dbPath: model.dbPath,
            }

        (_, ["settings", ..]) ->
            view = Views.Pages.pageSettings {}

            if partial then
                view
                |> respondTemplate 200 [
                    { name: "HX-Push-Url", value: "/settings" },
                ]
            else
                view
                |> Views.Layout.sidebar
                |> respondTemplate 200 [
                    { name: "HX-Push-Url", value: "/settings" },
                ]

        (Get, ["test404"]) -> Task.err (URLNotFound "Test404Error")
        (Get, ["test500"]) -> Task.err Test500Error
        _ -> Task.err (URLNotFound req.url)

staticFile : Str -> (Str -> Task Response _)
staticFile = \basePath -> \relPath ->

        path = "$(basePath)/$(relPath)"

        body =
            Path.fromStr path
            |> File.readBytes
            |> Task.mapErr! \err -> ErrGettingStaticFile path (Inspect.toStr err)

        bytesRead = List.len body

        info! "Read $(Num.toStr bytesRead) bytes for static file $(path)"

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

        Task.ok {
            status: 200,
            headers: [
                { name: "Cache-Control", value: "max-age=3600" },
                contentTypeHeader,
            ],
            body,
        }

logRequest : Request -> Task {} _
logRequest = \req ->
    date = Utc.now |> Task.map! Utc.toIso8601Str
    method = Http.methodToStr req.method
    url = req.url
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

#                Task.err (NewSession id)
#            else
#                Task.err err
