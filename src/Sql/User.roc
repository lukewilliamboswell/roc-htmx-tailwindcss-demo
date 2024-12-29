module [list!]

import Models.User exposing [User]
import web.SQLite3

list! : { dbPath : Str } => Result (List User) _
list! = \{ dbPath } ->

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

    rows =
        SQLite3.execute! {
            path: dbPath,
            query,
            bindings: [],
        }
        |> Result.mapErr? SqlErrGettingUsers

    parseUserRows rows []

parseUserRows : List (List SQLite3.Value), List User -> Result (List User) _
parseUserRows = \rows, acc ->
    when rows is
        [] -> Ok acc
        [[Integer id, String name, String avatar, String email, String biography, String position, String country, String status], .. as rest] ->
            parseUserRows
                rest
                (
                    List.append acc {
                        id,
                        name,
                        avatar,
                        email,
                        biography,
                        position,
                        country,
                        status,
                    }
                )

        row -> Err (UnexpectedValues "unexpected values, got row $(Inspect.toStr row)")
