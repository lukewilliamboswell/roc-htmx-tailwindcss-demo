module [list!]

import Models.User exposing [User]
import web.SQLite3

list! : { db_path : Str } => Result (List User) _
list! = \{ db_path } ->

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
            path: db_path,
            query,
            bindings: [],
        }
        |> Result.mapErr? SqlErrGettingUsers

    parse_user_rows rows []

parse_user_rows : List (List SQLite3.Value), List User -> Result (List User) _
parse_user_rows = \rows, acc ->
    when rows is
        [] -> Ok acc
        [[Integer id, String name, String avatar, String email, String biography, String position, String country, String status], .. as rest] ->
            parse_user_rows
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
