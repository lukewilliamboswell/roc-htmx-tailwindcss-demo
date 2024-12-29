module [Product, sample_data]

Product : {
    id : I64,
    name : Str,
    category : Str,
    technology : Str,
    description : Str,
    price : Str,
    discount : Str,
}

sample_data : List Product
sample_data = []
