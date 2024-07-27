app [main] {
    # TODO replace with 0.6.0 latest release when it is available
    pf: platform "https://github.com/roc-lang/basic-webserver/releases/download/0.6.0/LQS_Avcf8ogi1SqwmnytRD4SMYiZ4UcRCZwmAjj1RNY.tar.gz",
    html: "https://github.com/Hasnep/roc-html/releases/download/v0.6.0/IOyNfA4U_bCVBihrs95US9Tf5PGAWh3qvrBN4DRbK5c.tar.br",
    ansi: "https://github.com/lukewilliamboswell/roc-ansi/releases/download/0.1.1/cPHdNPNh8bjOrlOgfSaGBJDz6VleQwsPdW0LJK6dbGQ.tar.br",
    json: "https://github.com/lukewilliamboswell/roc-json/releases/download/0.10.0/KbIfTNbxShRX1A1FgXei1SpO5Jn8sgP6HP6PXbi-xyA.tar.br",
}

import pf.Stdout
import pf.Stderr
import pf.Task exposing [Task]
import pf.Http exposing [Request, Response]
import pf.Utc
import pf.Path
import pf.File
import pf.Url
import ansi.Color
import Helpers exposing [parseQueryParams, respondTemplate, info]
import Sql.Session
import Sql.Session
import Models.Session exposing [Session]
import Views.Pages
import Views.Layout
import Controllers.Product
import Controllers.User

staticBaseUrl = "static"

main : Request -> Task Response []
main = \req -> Task.onErr (handleReq req) \err ->
        when err is
            URLNotFound url ->
                methodStr = req.method |> Http.methodToStr
                errMsg = Str.joinWith ["404 NotFound" |> Color.fg Yellow, methodStr, url] " "
                Stderr.line! errMsg

                Views.Pages.error404 { staticBaseUrl }
                |> Views.Layout.normal
                |> respondTemplate 404 []

            InvalidSessionCookie ->
                Views.Pages.error404 { staticBaseUrl }
                |> Views.Layout.normal
                |> respondTemplate 404 []

            Unauthorized ->
                Views.Pages.error401 { staticBaseUrl }
                |> Views.Layout.normal
                |> respondTemplate 401 []

            NewSession sessionId ->
                # Redirect to the same URL with the new session ID
                Task.ok {
                    status: 303,
                    headers: [
                        { name: "Set-Cookie", value: "sessionId=$(Num.toStr sessionId)" },
                        { name: "Location", value: req.url },
                    ],
                    body: [],
                }

            _ ->
                errMsg = Str.joinWith ["500 Server Error" |> Color.fg Red, Inspect.toStr err] " "
                Stderr.line! errMsg

                Views.Pages.error500 { staticBaseUrl }
                |> Views.Layout.normal
                |> respondTemplate 500 []

handleReq : Request -> Task Response _
handleReq = \req ->

    logRequest! req # Log the date, time, method, and url to stdout

    urlSegments =
        req.url
        |> Url.fromStr
        |> Url.path
        |> Str.split "/"
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

    # dbPath = Env.var "DB_PATH" |> Task.mapErr! UnableToReadDbPATH
    dbPath = "../app.db"

    when (req.method, urlSegments) is
        (Get, ["static", .. as rest]) -> getStaticFile (rest |> Str.joinWith "/" |> Str.withPrefix "./")
        (Get, ["favicon.ico"]) -> getStaticFile "./favicon.ico"
        (Get, ["android-chrome-192x192.png"]) -> getStaticFile "./android-chrome-192x192.png"
        (Get, ["android-chrome-512x512.png"]) -> getStaticFile "./android-chrome-512x512.png"

        (Get, ["signin"]) ->
            Views.Pages.pageSignIn {
                staticBaseUrl,
            }
            |> Views.Layout.normal
            |> respondTemplate 200 []

        (Get, ["signup"]) ->
            Views.Pages.pageSignUp {
                staticBaseUrl,
            }
            |> Views.Layout.normal
            |> respondTemplate 200 []

        (Get, ["forgotpassword"]) ->
            Views.Pages.pageForgotPassword {
                staticBaseUrl,
            }
            |> Views.Layout.normal
            |> respondTemplate 200 []

        (Get, ["resetpassword"]) ->
            Views.Pages.pageResetPassword {
                staticBaseUrl,
            }
            |> Views.Layout.normal
            |> respondTemplate 200 []

        (Get, ["profilelock"]) ->
            Views.Pages.pageProfileLock {
                staticBaseUrl,
            }
            |> Views.Layout.normal
            |> respondTemplate 200 []

        (Get, [""]) | (_, ["products",..]) ->
            Controllers.Product.handleRoutes {
                req,
                urlSegments: List.dropFirst urlSegments 1,
                dbPath,
                getSession,
            }

        (_, ["users",..]) ->
            Controllers.User.handleRoutes {
                req,
                urlSegments: List.dropFirst urlSegments 1,
                dbPath,
                getSession,
            }

        (_, ["settings",..]) ->

            view = Views.Pages.pageSettings { staticBaseUrl }

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

getStaticFile : Str -> Task Response _
getStaticFile = \path ->

    body =
        Path.fromStr path
            |> File.readBytes
            |> Task.mapErr! \err -> ErrGettingStaticFile path (Inspect.toStr err)

    bytesRead = List.len body
    info! "Read $(Num.toStr bytesRead) bytes for static file $(path)"

    contentTypeHeader =
        if Str.endsWith path ".svg" then
            { name: "Content-Type", value: "image/svg+xml" }
        else if Str.endsWith path ".css" then
            { name: "Content-Type", value: "text/css" }
        else if Str.endsWith path ".js" then
            { name: "Content-Type", value: "application/javascript" }
        else if Str.endsWith path ".ico" then
            { name: "Content-Type", value: "image/x-icon" }
        else if Str.endsWith path ".png" then
            { name: "Content-Type", value: "image/png" }
        else if Str.endsWith path ".jpg" then
            { name: "Content-Type", value: "image/jpeg" }
        else if Str.endsWith path ".jpeg" then
            { name: "Content-Type", value: "image/jpeg" }
        else if Str.endsWith path ".gif" then
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

logRequest : Request -> Task {} *
logRequest = \req ->
    date = Utc.now |> Task.map! Utc.toIso8601Str
    method = Http.methodToStr req.method
    url = req.url
    # body can be large, don't log it
    #body = req.body |> Str.fromUtf8 |> Result.withDefault "<invalid utf8 body>"
    Stdout.line! "$(date) $(method) $(url)"

getSession : Request, Str -> Task Session _
getSession = \req, dbPath ->
    Sql.Session.parse req
        |> Task.fromResult
        |> Task.await \id -> Sql.Session.get id dbPath
        |> Task.onErr \err ->
            if err == SessionNotFound || err == NoSessionCookie then
                id = Sql.Session.new! dbPath

                Task.err (NewSession id)
            else
                Task.err err
