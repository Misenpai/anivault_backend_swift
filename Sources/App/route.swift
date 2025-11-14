






import Vapor

func routes(_ app: Application) throws {
    app.get("health"){
        req in
        return ["status": "ok", "timestamp": Date().ISO8601Format()]
    }
    
    let api = app.grouped("api", "v1")
    
    let userRepository = UserRepository()
    let animeRepository = AnimeRepository()
    
    let jwtService = JWTService()
    let authService = AuthService(userRepository: userRepository, jwtService: jwtService)
    let friendService = FriendService()
    let profileService = ProfileService(friendService: friendService)
    let animeService = AnimeService(animeRepository: animeRepository)
    let jikanService = JikanService(client: app.client)
    
    let authController = AuthController(authService: authService)
    let userController = UserController(userService: UserService(userRepository: userRepository))
    let friendController = FriendController(friendService: friendService)
    let profileController = ProfileController(profileService: profileService)
    let animeController = AnimeController(jikanService: jikanService, animeService: animeService)
    
    try api.register(collection: authController)
    try api.register(collection: userController)
    try api.register(collection: friendController)
    try api.register(collection: profileController)
    try api.register(collection: animeController)
}
