//
//  main.swift
//  anivault_backend
//
//  Created by Sumit Sinha on 08/11/25.
//

import App
import Vapor

var env = try Environment.detect()
try LoggingSystem.bootstrap(from: &env)
let app = Application(env)
defer {app.shutdown()}
try configure(app)
try app.run()
