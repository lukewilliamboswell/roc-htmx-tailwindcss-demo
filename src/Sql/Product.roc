module [list!]

import Models.Product exposing [Product]
import web.SQLite3

list! : { dbPath : Str } => Result (List Product) _
list! = \{ dbPath } ->

    query =
        """
        SELECT
          [id],
          [name],
          [category],
          [technology],
          [description],
          [price],
          [discount]
        FROM  [products];
        """

    rows =
        SQLite3.execute! {
            path: dbPath,
            query,
            bindings: [],
        }
        |> Result.mapErr? SqlErrGettingProducts

    parseProductRows rows []

parseProductRows : List (List SQLite3.Value), List Product -> Result (List Product) _
parseProductRows = \rows, acc ->
    when rows is
        [] -> Ok acc
        [[Integer id, String name, String category, String technology, String description, String price, String discount], .. as rest] ->
            parseProductRows
                rest
                (
                    List.append acc {
                        id,
                        name,
                        category,
                        technology,
                        description,
                        price,
                        discount,
                    }
                )

        row -> Err (UnexpectedValues "unexpected values, got row $(Inspect.toStr row)")
