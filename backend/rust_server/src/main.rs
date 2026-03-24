mod handlers;
mod routes;

use actix_cors::Cors;
use actix_web::{App, HttpServer, middleware};
use dotenv::dotenv;
use routes::init_routes;

#[actix_web::main]
async fn main() -> std::io::Result<()> {
    dotenv().ok();
    env_logger::init_from_env(env_logger::Env::new().default_filter_or("info"));

    let port: u16 = std::env::var("PORT")
        .unwrap_or_else(|_| "8000".to_string())
        .parse()
        .expect("PORT must be a valid number");

    log::info!("Starting WhiteCane server on port {}", port);

    HttpServer::new(|| {
        let cors = Cors::default()
            .allow_any_origin()
            .allow_any_method()
            .allow_any_header()
            .max_age(3600);

        App::new()
            .wrap(cors)
            .wrap(middleware::Logger::default())
            .configure(init_routes)
    })
    .bind(("0.0.0.0", port))?
    .run()
    .await
}
