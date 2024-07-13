app [main] {
    pf: platform "https://github.com/roc-lang/basic-webserver/releases/download/0.5.0/Vq-iXfrRf-aHxhJpAh71uoVUlC-rsWvmjzTYOJKhu4M.tar.br",
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
import json.Json
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
        (Get, [""]) | (Get, ["settings"]) ->
            queryParams =
                req.url
                |> parseQueryParams
                |> Result.withDefault (Dict.empty {})

            displaySideBar =
                queryParams
                |> Dict.get "sidebar"
                |> Result.map \val -> if val == "true" then Bool.true else Bool.false
                |> Result.withDefault Bool.false

            displayDarkMode =
                queryParams
                |> Dict.get "dark"
                |> Result.map \val -> if val == "true" then Bool.true else Bool.false
                |> Result.withDefault Bool.false

            newParams =
                fromBool = \b -> if b then "true" else "false"

                queryParams
                |> Dict.insert "dark" (fromBool displayDarkMode)
                |> Dict.insert "sidebar" (fromBool displaySideBar)

            newUrl = Helpers.replaceQueryParams { url: req.url, params: newParams }

            baseWithBodyRTL {
                header: headerRTL,
                content: dashboardRTL {
                    displaySideBar,
                    contentRTL: settingsPage,
                },
                navBar: navBarRTL { displaySideBar, displayDarkMode },
            }
            |> respondTemplate [
                { name: "HX-Push-Url", value: Str.toUtf8 newUrl },
            ]

        (Get, ["dashboard", "sidebar"]) -> sidebarRTL |> respondTemplate []

        (Get, ["products"]) ->
            queryParams =
                req.url
                |> parseQueryParams
                |> Result.withDefault (Dict.empty {})

            displaySideBar =
                queryParams
                |> Dict.get "sidebar"
                |> Result.map \val -> if val == "true" then Bool.true else Bool.false
                |> Result.withDefault Bool.false

            displayDarkMode =
                queryParams
                |> Dict.get "dark"
                |> Result.map \val -> if val == "true" then Bool.true else Bool.false
                |> Result.withDefault Bool.false

            products = getProductsFromJSONFile!

            baseWithBodyRTL {
                header: headerRTL,
                content: dashboardRTL {
                    displaySideBar,
                    contentRTL: productsPage {
                        products,
                    },
                },
                navBar: navBarRTL { displaySideBar, displayDarkMode },
            }
            |> respondTemplate []

        (Get, ["asdf"]) -> headerRTL |> respondTemplate []
        _ -> Task.err (URLNotFound req.url)

staticBaseUrl = "static"

productsPage = \{products} -> Generated.Pages.productsPage {
        products,
    }

Product : {
    name : Str,
    category : Str,
    technology : Str,
    id : U64,
    description : Str,
    price : Str,
    discount : Str,
}

getProductsFromJSONFile : Task (List Product) _
getProductsFromJSONFile =

    path = "./products.json"

    bytes =
        File.readBytes (Path.fromStr path)
            |> Task.mapErr! \err -> ErrReadingJSONFile path err

    products =
        Decode.fromBytes bytes Json.utf8
            |> Task.fromResult
            |> Task.mapErr! \err -> ErrDecodingJSONFile path err

    Task.ok products

settingsPage = Generated.Pages.settingsPage {
    staticBaseUrl,
    pageName: "Settings",
}

baseWithBodyRTL = \{ header, content, navBar } -> Generated.Pages.baseWithBody {
        contentRTL: content,
        navBarRTL: navBar,
        headerRTL: header,
        isWhiteBackground: Bool.true,
    }

navBarRTL = \{ displaySideBar, displayDarkMode } -> Generated.Pages.navBarDashboard {
        displaySideBar,
        displayDarkMode,
        relURL: "",
        staticBaseUrl,
    }

dashboardRTL = \{ displaySideBar, contentRTL } -> Generated.Pages.dashboard {
        contentRTL,
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
        authors: "Themesberg",
        description: "Get started with a free and open-source admin dashboard layout built with Tailwind CSS and Flowbite featuring charts, widgets, CRUD layouts, authentication pages, and more",
        staticBaseUrl,
        stylesheetRTL: Generated.Pages.stylesheet { staticBaseUrl },
        title: "Tailwind CSS Admin Dashboard - Flowbite",
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
        else if Str.endsWith path ".png" then
            { name: "Content-Type", value: Str.toUtf8 "image/png" }
        else if Str.endsWith path ".jpg" then
            { name: "Content-Type", value: Str.toUtf8 "image/jpeg" }
        else if Str.endsWith path ".jpeg" then
            { name: "Content-Type", value: Str.toUtf8 "image/jpeg" }
        else if Str.endsWith path ".gif" then
            { name: "Content-Type", value: Str.toUtf8 "image/gif" }
        else
            { name: "Content-Type", value: Str.toUtf8 "application/octet-stream" }

    Task.ok {
        status: 200,
        headers: [
            { name: "Cache-Control", value: Str.toUtf8 "max-age=3600" },
            contentTypeHeader,
        ],
        body,
    }

respondTemplate : Str, _ -> Task Response []_
respondTemplate = \html, headers ->
    Task.ok {
        status: 200,
        headers: List.concat headers [
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
