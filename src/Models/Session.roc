module [
    Session,
    is_authenticated,
]

Session : {
    id : I64,
    user : [Guest, LoggedIn Str],
}

is_authenticated : [Guest, LoggedIn Str] -> Result {} [Unauthorized]
is_authenticated = \user ->
    if user == Guest then
        Err Unauthorized
    else
        Ok {}
