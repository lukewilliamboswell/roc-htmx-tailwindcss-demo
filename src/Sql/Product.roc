module [list]

import Models.Product exposing [Product]
import web.Sqlite

list : { dbPath : Str } -> Task (List Product) _
list = \{ dbPath } ->

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

    Sqlite.query {
        path : dbPath,
        query,
        bindings : [],
        rows :{ Sqlite.decodeRecord <-
            id: Sqlite.i64 "id",
            name: Sqlite.str "id",
            category: Sqlite.str "category",
            technology: Sqlite.str "technology",
            description: Sqlite.str "description",
            price: Sqlite.str "price",
            discount: Sqlite.str "discount",
        },
    }
    |> Task.mapErr SqlErrGettingProducts
