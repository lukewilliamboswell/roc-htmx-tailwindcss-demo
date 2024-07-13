app [main] {
    pf: platform "https://github.com/roc-lang/basic-webserver/releases/download/0.5.0/Vq-iXfrRf-aHxhJpAh71uoVUlC-rsWvmjzTYOJKhu4M.tar.br",
    html: "https://github.com/Hasnep/roc-html/releases/download/v0.6.0/IOyNfA4U_bCVBihrs95US9Tf5PGAWh3qvrBN4DRbK5c.tar.br",
    ansi: "https://github.com/lukewilliamboswell/roc-ansi/releases/download/0.1.1/cPHdNPNh8bjOrlOgfSaGBJDz6VleQwsPdW0LJK6dbGQ.tar.br",
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
import Generated.Pages
import Helpers exposing [respondHtml, decodeFormValues, parseQueryParams]

main : Request -> Task Response []
main = \req -> Task.onErr (handleReq req) \err ->
        when err is
            URLNotFound url -> respondCodeLogError (Str.joinWith ["404 NotFound" |> Color.fg Red, url] " ") 404
            _ -> respondCodeLogError (Str.joinWith ["SERVER ERROR" |> Color.fg Red, Inspect.toStr err] " ") 500

handleReq : Request -> Task Response _
handleReq = \req ->

    logRequest! req # Log the date, time, method, and url to stdout

    urlSegments =
        req.url
        |> Url.fromStr
        |> Url.path
        |> Str.split "/"
        |> List.dropFirst 1

    when (req.method, urlSegments) is
        (Get, ["static", .. as rest]) -> getStaticFile (rest |> Str.joinWith "/" |> Str.withPrefix "./")
        (Get, ["favicon.ico"]) -> getStaticFile "./favicon.ico"
        (Get, [""]) ->
            queryParams =
                req.url
                |> parseQueryParams
                |> Result.withDefault (Dict.empty {})

            displaySideBar =
                queryParams
                |> Dict.get "sidebar"
                |> Result.map \val -> if val == "true" then Bool.true else Bool.false
                |> Result.withDefault Bool.false

            baseWithBodyRTL {
                header: headerRTL,
                content: dashboardRTL { displaySideBar },
                navBar: navBarRTL,
            }
            |> respondTemplate

        (Get, ["dashboard", "sidebar"]) -> sidebarRTL |> respondTemplate
        (Get, ["asdf"]) -> headerRTL |> respondTemplate
        _ -> Task.err (URLNotFound req.url)

staticBaseUrl = "static"

baseWithBodyRTL = \{ header, content, navBar } -> Generated.Pages.baseWithBody {
        contentRTL: content,
        navBarRTL: navBar,
        headerRTL: header,
        isWhiteBackground: Bool.true,
    }

navBarRTL = Generated.Pages.navBarDashboard {
    relURL: "",
    staticBaseUrl,
}

dashboardRTL = \{ displaySideBar } -> Generated.Pages.dashboard {
        contentRTL: "NOTHING TO SEE YET",
        footerDashboardRTL,
        displaySideBar,
        sidebarRTL,
    }

footerDashboardRTL = Generated.Pages.footerDashboard {
    copyright: "Flowbite Authors",
}

sidebarRTL = Generated.Pages.sidebar {
    page: SettingsPage,
    relURL: "/",
}

headerRTL =
    Generated.Pages.header {
        authors: "authors",
        description: "description",
        staticBaseUrl,
        stylesheetRTL: Generated.Pages.stylesheet { staticBaseUrl },
        title: "title",
    }

getStaticFile : Str -> Task Response _
getStaticFile = \path ->

    body =
        Path.fromStr path
            |> File.readBytes
            |> Task.mapErr! \err -> ErrGettingStaticFile path err

    bytesRead = List.len body
    info! "Read $(Num.toStr bytesRead) bytes for static file $(path)"

    contentTypeHeader =
        if Str.endsWith path ".svg" then
            { name: "Content-Type", value: Str.toUtf8 "image/svg+xml" }
        else if Str.endsWith path ".css" then
            { name: "Content-Type", value: Str.toUtf8 "text/css" }
        else if Str.endsWith path ".js" then
            { name: "Content-Type", value: Str.toUtf8 "application/javascript" }
        else if Str.endsWith path ".ico" then
            { name: "Content-Type", value: Str.toUtf8 "image/x-icon" }
        else
            { name: "Content-Type", value: Str.toUtf8 "application/octet-stream" }

    Task.ok {
        status: 200,
        headers: [
            # TODO increase max-age for a real app
            { name: "Cache-Control", value: Str.toUtf8 "max-age=120" },
            contentTypeHeader,
        ],
        body,
    }

respondTemplate : _ -> Task Response []_
respondTemplate = \html ->
    Task.ok {
        status: 200,
        headers: [
            { name: "Content-Type", value: Str.toUtf8 "text/html; charset=utf-8" },
        ],
        body: html |> Str.toUtf8,
    }

respondCodeLogError : Str, U16 -> Task Response []
respondCodeLogError = \msg, code ->
    Stderr.line! msg
    Task.ok! {
        status: code,
        headers: [],
        body: [],
    }

logRequest : Request -> Task {} *
logRequest = \req ->
    date = Utc.now |> Task.map! Utc.toIso8601Str
    method = Http.methodToStr req.method
    url = req.url
    body = req.body |> Str.fromUtf8 |> Result.withDefault "<invalid utf8 body>"
    Stdout.line! "$(date) $(method) $(url) $(body)"

info : Str -> Task {} _
info = \msg ->
    Stdout.line! "\u(001b)[34mINFO:\u(001b)[0m $(msg)"
