module [
    new,
    parse,
    get,
]

import pf.Task exposing [Task]
import pf.Http exposing [Request]
import pf.Sqlite
import Models.Session exposing [Session]

new : Str -> Task I64 _
new = \path ->

    Sqlite.execute! {
        path,
        query: "INSERT INTO sessions (session_id) VALUES (abs(random()));",
        bindings: [],
    }

    ids =
        Sqlite.query!
            {
                path,
                query: "SELECT last_insert_rowid();",
                bindings: [],
            }
            (Sqlite.i64 "id")

    when List.first ids is
        Ok id -> Task.ok id
        Err _ -> Task.err MoreThanOneInserted

get : I64, Str -> Task Session _
get = \sessionId, path ->

    notFoundStr = "NOT_FOUND"

    Sqlite.query
        {
            path,
            query:
            """
            SELECT
                sessions.session_id,
                COALESCE(users.name,'$(notFoundStr)') AS 'username'
            FROM sessions
            LEFT OUTER JOIN users
            ON sessions.user_id = users.id
            WHERE sessions.session_id = :sessionId;
            """,
            bindings: [{ name: ":sessionId", value: Integer sessionId }],
        }
        { Sqlite.decodeRecord <-
            id: Sqlite.i64 "id",
            user: Sqlite.str "username",
        }
    |> Task.mapErr \_ -> SessionNotFound
    |> Task.await \ids ->
        ids
        |> List.first
        |> Result.map \{ id, user } -> { id, user: LoggedIn user }
        |> Task.fromResult

parse : Request -> Result I64 [NoSessionCookie, InvalidSessionCookie]
parse = \req ->
    when req.headers |> List.keepIf \reqHeader -> reqHeader.name == "cookie" is
        [reqHeader] ->
            Str.split reqHeader.value "="
            |> List.get 1
            |> Result.try Str.toI64
            |> Result.mapErr \_ -> InvalidSessionCookie

        _ -> Err NoSessionCookie
