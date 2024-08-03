module [list]

import Models.User exposing [User]
import pf.Task exposing [Task]
import pf.Sqlite

list : { dbPath : Str } -> Task (List User) _
list = \{ dbPath } ->
    Sqlite.query {
        path: dbPath,
        query:
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
        """,
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
