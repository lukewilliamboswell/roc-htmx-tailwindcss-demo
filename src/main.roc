app [Model, init!, respond!] {
    web: platform "https://github.com/roc-lang/basic-webserver/releases/download/0.11.0/yWHkcVUt_WydE1VswxKFmKFM5Tlu9uMn6ctPVYaas7I.tar.br",
}

Model : {}

init! : {} => Result Model [Exit I32 Str]_
init! = \_ -> Ok {}

respond! : _, Model => Result _ _
respond! = \_, _ -> Err TODO
