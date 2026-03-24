use actix_web::{get, HttpResponse, Responder};
use serde::Serialize;

#[derive(Serialize)]
struct LocationResponse {
    latitude: f64,
    longitude: f64,
    accuracy: f64,
    message: String,
}

#[derive(Serialize)]
struct HealthResponse {
    status: String,
    version: String,
}

/// 현재 위치 조회 API
///
/// TODO: 실제 GPS 기반 또는 IP 기반 위치 서비스 연동
/// 현재는 기본 좌표값을 반환합니다.
#[get("/api/location")]
pub async fn get_current_location() -> impl Responder {
    // TODO: 실제 위치 서비스 연동
    // - GPS 데이터 수신
    // - IP 기반 위치 추정
    // - 사용자 마지막 위치 반환 등
    HttpResponse::Ok().json(LocationResponse {
        latitude: 0.0,
        longitude: 0.0,
        accuracy: 0.0,
        message: "TODO: 위치 서비스 연동 필요".to_string(),
    })
}

/// 서버 헬스체크
#[get("/health")]
pub async fn health_check() -> impl Responder {
    HttpResponse::Ok().json(HealthResponse {
        status: "ok".to_string(),
        version: env!("CARGO_PKG_VERSION").to_string(),
    })
}
