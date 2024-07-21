module [
    Session,
    isAuthenticated,
]

Session : {
    id : I64,
    user : [Guest, LoggedIn Str],
}

isAuthenticated : [Guest, LoggedIn Str] -> Result {} [Unauthorized]
isAuthenticated = \user ->
    if user == Guest then
        Err Unauthorized
    else
        Ok {}
