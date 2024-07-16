app [main] {
    pf: platform "../basic-webserver/platform/main.roc",
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
import Helpers exposing [parseQueryParams]

main : Request -> Task Response []
main = \req -> Task.onErr (handleReq req) \err ->
        when err is
            URLNotFound url ->
                errMsg = Str.joinWith ["404 NotFound" |> Color.fg Yellow, url] " "
                Stderr.line! errMsg

                Generated.Pages.error404 { staticBaseUrl }
                |> layoutNormal
                |> respondTemplate 404 []

            _ ->
                errMsg = Str.joinWith ["500 Server Error" |> Color.fg Red, Inspect.toStr err] " "
                Stderr.line! errMsg

                Generated.Pages.error500 { staticBaseUrl }
                |> layoutNormal
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

    when (req.method, urlSegments) is
        (Get, ["static", .. as rest]) -> getStaticFile (rest |> Str.joinWith "/" |> Str.withPrefix "./")
        (Get, ["favicon.ico"]) -> getStaticFile "./favicon.ico"
        (Get, ["signin"]) ->
            Generated.Pages.pageSignIn {
                staticBaseUrl,
            }
            |> layoutNormal
            |> respondTemplate 200 []

        (Get, ["signup"]) ->
            Generated.Pages.pageSignUp {
                staticBaseUrl,
            }
            |> layoutNormal
            |> respondTemplate 200 []

        (Get, ["forgotpassword"]) ->
            Generated.Pages.pageForgotPassword {
                staticBaseUrl,
            }
            |> layoutNormal
            |> respondTemplate 200 []

        (Get, ["resetpassword"]) ->
            Generated.Pages.pageResetPassword {
                staticBaseUrl,
            }
            |> layoutNormal
            |> respondTemplate 200 []

        (Get, ["profilelock"]) ->
            Generated.Pages.pageProfileLock {
                staticBaseUrl,
            }
            |> layoutNormal
            |> respondTemplate 200 []

        (Get, [""]) | (Get, ["products"]) | (Get, ["settings"]) | (Get, ["users"]) ->
            queryParams =
                req.url
                |> parseQueryParams
                |> Result.withDefault (Dict.empty {})

            partial =
                queryParams
                |> Dict.get "partial"
                |> Result.map \val -> if val == "true" then Bool.true else Bool.false
                |> Result.withDefault Bool.false

            page =
                (
                    if List.startsWith urlSegments ["products"] then
                        Task.ok ProductsPage
                    else if List.startsWith urlSegments ["settings"] then
                        Task.ok SettingsPage
                    else if List.startsWith urlSegments ["users"] then
                        Task.ok UsersPage
                    else
                        Task.ok ProductsPage
                    # TODO restore when we have a default page
                    # Task.err (URLNotFound req.url)
                )!

            newParams =
                queryParams
                |> Dict.remove "partial"

            newUrl = Helpers.replaceQueryParams { url: req.url, params: newParams }

            if partial then respondPagePartial { newUrl, page } else respondPageFull { newUrl, page }

        (Get, ["test404"]) -> Task.err (URLNotFound "Test404Error")
        (Get, ["test500"]) -> Task.err Test500Error
        _ -> Task.err (URLNotFound req.url)

staticBaseUrl = "static"

headerTemplate : Str
headerTemplate = Generated.Pages.header {
    staticBaseUrl,
    authors: "Themesberg",
    description: "Get started with a free and open-source admin dashboard layout built with Tailwind CSS and Flowbite featuring charts, widgets, CRUD layouts, authentication pages, and more",
    stylesheet: Generated.Pages.stylesheet { staticBaseUrl },
    title: "Tailwind CSS Admin Dashboard - Flowbite",
}

footerTemplate : Str
footerTemplate = Generated.Pages.footer {
    copyright: "Flowbite Authors",
}

navbarTemplate : Str
navbarTemplate = Generated.Pages.navbar {
    relURL: "",
    staticBaseUrl,
}

sidebarTemplate : Str
sidebarTemplate = Generated.Pages.sidebar {
    ariaLabel: "Sidebar",
}

layoutNormal = \content ->
    Generated.Pages.layoutNormal {
        header: headerTemplate,
        content: content,
        footer: "",
        navbar: "",
    }

layoutSidebar = \content ->
    Generated.Pages.layoutSidebar {
        header: headerTemplate,
        content,
        footer: footerTemplate,
        navbar: navbarTemplate,
        sidebar: sidebarTemplate,
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

    path = "./sample-products.json"

    bytes =
        File.readBytes (Path.fromStr path)
            |> Task.mapErr! \err -> ErrReadingJSONFile path err

    products =
        Decode.fromBytes bytes Json.utf8
            |> Task.fromResult
            |> Task.mapErr! \err -> ErrDecodingJSONFile path err

    Task.ok products

User : {
    id : U64,
    name : Str,
    avatar : Str,
    email : Str,
    biography : Str,
    position : Str,
    country : Str,
    status : Str,
}

getUsersFromJSONFile : Task (List User) _
getUsersFromJSONFile =
    path = "./sample-users.json"

    bytes =
        File.readBytes (Path.fromStr path)
            |> Task.mapErr! \err -> ErrReadingJSONFile path err

    products =
        Decode.fromBytes bytes Json.utf8
            |> Task.fromResult
            |> Task.mapErr! \err -> ErrDecodingJSONFile path err

    Task.ok products

respondPageFull : _ -> Task Response _
respondPageFull = \{ page, newUrl } ->
    when page is
        SettingsPage ->
            Generated.Pages.pageSettings { staticBaseUrl }
            |> layoutSidebar
            |> respondTemplate 200 [
                { name: "HX-Push-Url", value: newUrl },
            ]

        ProductsPage ->
            products = getProductsFromJSONFile!

            Generated.Pages.pageProducts {
                products,
            }
            |> layoutSidebar
            |> respondTemplate 200 [
                { name: "HX-Push-Url", value: newUrl },
            ]

        UsersPage ->
            users = getUsersFromJSONFile!

            Generated.Pages.pageUsers {
                staticBaseUrl,
                users,
            }
            |> layoutSidebar
            |> respondTemplate 200 [
                { name: "HX-Push-Url", value: newUrl },
            ]

respondPagePartial : _ -> Task Response _
respondPagePartial = \{ page, newUrl } ->
    when page is
        SettingsPage ->
            Generated.Pages.pageSettings { staticBaseUrl }
            |> respondTemplate 200 [
                { name: "HX-Push-Url", value: newUrl },
            ]

        ProductsPage ->
            products = getProductsFromJSONFile!

            Generated.Pages.pageProducts {
                products,
            }
            |> respondTemplate 200 [
                { name: "HX-Push-Url", value: newUrl },
            ]

        UsersPage ->
            users = getUsersFromJSONFile!
            Generated.Pages.pageUsers {
                staticBaseUrl,
                users,
            }
            |> respondTemplate 200 [
                { name: "HX-Push-Url", value: newUrl },
            ]

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

respondTemplate : Str, U16, _ -> Task Response []_
respondTemplate = \html, status, headers ->
    Task.ok {
        status,
        headers: List.concat headers [
            { name: "Content-Type", value: "text/html; charset=utf-8" },
        ],
        body: html |> Str.toUtf8,
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
