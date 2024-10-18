module [list]

import Models.User exposing [User]
import web.Sqlite

list : { dbPath : Str } -> Task (List User) _
list = \{ dbPath } ->

    query =
        """
        SELECT
          [id],
          [name],
          [avatar],
          [email],
          [biography],
          [position],
          [country],
          [status]
        FROM [users];
        """

    Sqlite.query {
        path: dbPath,
        query,
        bindings: [],
        rows: { Sqlite.decodeRecord <-
            id: Sqlite.i64 "id",
            name: Sqlite.str "name",
            avatar: Sqlite.str "avatar",
            email: Sqlite.str "email",
            biography: Sqlite.str "biography",
            position: Sqlite.str "position",
            country: Sqlite.str "country",
            status: Sqlite.str "status",

        },
    }
    |> Task.mapErr \err -> SqlErrGettingUsers err
