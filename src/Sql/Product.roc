module [list]

import Models.Product exposing [Product]
import pf.Task exposing [Task]
import pf.Sqlite

list : { dbPath : Str } -> Task (List Product) _
list = \{ dbPath } ->
    Task.err TODO
    #Sqlite.query {
    #    path: dbPath,
    #    query:
    #    """
    #    SELECT
    #    [id],
    #    [name],
    #    [category],
    #    [technology],
    #    [description],
    #    [price],
    #    [discount]
    #    FROM  [products];
    #    """,
    #    bindings: [],
    #    rows: { Sqlite.decodeRecord <-
    #        id: Sqlite.i64 "id",
    #        name: Sqlite.str "name",
    #        category: Sqlite.str "category",
    #        technology: Sqlite.str "technology",
    #        description: Sqlite.str "description",
    #        price: Sqlite.str "price",
    #        discount: Sqlite.str "discount",

    #    },
    #}
    #|> Task.mapErr SqlErrGettingProducts
