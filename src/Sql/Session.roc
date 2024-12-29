module [
    new,
    parse,
    get,
]

import web.Http exposing [Request]
import web.SQLite3
import Models.Session exposing [Session]

new : Str -> Task I64 _
new = \path ->

    query =
        "INSERT INTO sessions (session_id) VALUES (abs(random()));"

    _ =
        SQLite3.execute { path, query, bindings: [] }
        |> Task.map_err! \err -> SqlError err

    rows =
        { path, query: "SELECT last_insert_rowid();", bindings: [] }
        |> SQLite3.execute
        |> Task.on_err! \err -> SqlError err |> Task.err

    when rows is
        [] -> Task.err (UnexpectedValues "unexpected values in new Session, got NIL rows")
        [[Integer id], ..] -> Task.ok id
        _ -> Task.err (UnexpectedValues "unexpected values in new Session, got $(Inspect.toStr rows)")

parse : Request -> Result I64 [NoSessionCookie, InvalidSessionCookie]
parse = \req ->
    when req.headers |> List.keep_if \req_header -> req_header.name == "cookie" is
        [req_header] ->
            Str.splitOn req_header.value "="
            |> List.get 1
            |> Result.try Str.toI64
            |> Result.mapErr \_ -> InvalidSessionCookie

        _ -> Err NoSessionCookie

get : I64, Str -> Task Session _
get = \session_id, path ->

    not_found_str = "NOT_FOUND"

    query =
        """
        SELECT
            sessions.session_id,
            COALESCE(users.name,'$(not_found_str)') AS 'username'
        FROM sessions
        LEFT OUTER JOIN users
        ON sessions.user_id = users.id
        WHERE sessions.session_id = :sessionId;
        """

    bindings = [{ name: ":sessionId", value: Integer session_id }]

    rows = SQLite3.execute { path, query, bindings } |> Task.map_err! SqlErrGettingSession

    when rows is
        [] -> Task.err SessionNotFound
        [[Integer id, String _username], ..] ->
            Task.ok { id, user: LoggedIn "Demo User" }

        _ -> Task.err (UnexpectedValues "unexpected values in get Session, got $(Inspect.toStr rows)")
