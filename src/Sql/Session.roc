module [
    new,
    parse,
    get,
]

import web.Http exposing [Request]
import web.Sqlite
import Models.Session exposing [Session]

new : Str -> Task I64 _
new = \path ->

    Sqlite.execute {
        path,
        query: "INSERT INTO sessions (session_id) VALUES (abs(random()));",
        bindings: [],
    }
        |> Task.mapErr! \err -> SqlError err

    Sqlite.queryExactlyOne {
        path,
        query: "SELECT last_insert_rowid();",
        bindings: [],
        row: Sqlite.i64 "id",
    }
        |> Task.mapErr! \err ->
            when err is
                NoRowsReturned -> UnexpectedValues "unexpected values in new Session, got NIL rows"
                TooManyRowsReturned -> UnexpectedValues "unexpected values in new Session, got TOO MANY rows"
                e -> SqlError e

parse : Request -> Result I64 [NoSessionCookie, InvalidSessionCookie]
parse = \req ->
    when req.headers |> List.keepIf \reqHeader -> reqHeader.name == "cookie" is
        [reqHeader] ->
            Str.split reqHeader.value "="
            |> List.get 1
            |> Result.try Str.toI64
            |> Result.mapErr \_ -> InvalidSessionCookie

        _ -> Err NoSessionCookie

get : I64, Str -> Task Session _
get = \sessionId, path ->

    notFoundStr = "NOT_FOUND"

    query =
        """
        SELECT
            sessions.session_id,
            COALESCE(users.name,'$(notFoundStr)') AS 'username'
        FROM sessions
        LEFT OUTER JOIN users
        ON sessions.user_id = users.id
        WHERE sessions.session_id = :sessionId;
        """

    Sqlite.queryExactlyOne {
        path,
        query,
        bindings: [{ name: ":sessionId", value: Integer sessionId }],
        row: { Sqlite.decodeRecord <-
            id: Sqlite.i64 "sessions.session_id",
            user: Sqlite.str "username" |> Sqlite.mapValue LoggedIn,
        },
    }
        |> Task.mapErr! SqlErrGettingSession
