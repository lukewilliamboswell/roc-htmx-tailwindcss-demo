module [list!]

import Models.Product exposing [Product]
import web.SQLite3

list! : { db_path : Str } => Result (List Product) _
list! = \{ db_path } ->

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
            path: db_path,
            query,
            bindings: [],
        }
        |> Result.mapErr? SqlErrGettingProducts

    parse_product_rows rows []

parse_product_rows : List (List SQLite3.Value), List Product -> Result (List Product) _
parse_product_rows = \rows, acc ->
    when rows is
        [] -> Ok acc
        [[Integer id, String name, String category, String technology, String description, String price, String discount], .. as rest] ->
            parse_product_rows
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
