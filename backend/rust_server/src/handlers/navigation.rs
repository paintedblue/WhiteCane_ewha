use actix_web::{get, post, web, HttpResponse, Responder};
use serde::{Deserialize, Serialize};
use std::collections::HashMap;

#[derive(Debug, Deserialize, Serialize)]
pub struct Coordinate {
    pub latitude: f64,
    pub longitude: f64,
}

#[derive(Debug, Deserialize)]
pub struct RouteRequest {
    pub start: Coordinate,
    pub end: Coordinate,
    pub wheelchair_version: Option<String>,
}

#[derive(Debug, Serialize)]
pub struct RouteResponse {
    pub duration: String,
    pub distance: String,
    pub route: Vec<Coordinate>,
    pub warnings: Vec<String>,
}

/// 샘플 노드 좌표 맵 (node_id -> (latitude, longitude))
fn node_coordinates() -> HashMap<&'static str, (f64, f64)> {
    let mut map = HashMap::new();
    map.insert("NODE_ECC",          (37.56237, 126.94700));
    map.insert("NODE_LIBRARY",      (37.56360, 126.94780));
    map.insert("NODE_STUDENT_HALL", (37.56310, 126.94740));
    map.insert("NODE_POSCO",        (37.56280, 126.94810));
    map.insert("NODE_SCIENCE",      (37.56350, 126.94830));
    map.insert("NODE_CAFETERIA",    (37.56290, 126.94730));
    map.insert("NODE_HEALTH",       (37.56300, 126.94760));
    map.insert("NODE_MAIN_GATE",    (37.56170, 126.94690));
    map
}

/// node_id로 포인트 좌표 조회
///
/// GET /api/navigation/node_coordinates/{node_id}
#[get("/api/navigation/node_coordinates/{node_id}")]
pub async fn get_node_coordinates(node_id: web::Path<String>) -> impl Responder {
    let node_id = node_id.into_inner();
    log::info!("노드 좌표 조회: {}", node_id);

    let coords = node_coordinates();
    match coords.get(node_id.as_str()) {
        Some(&(lat, lng)) => HttpResponse::Ok().json(serde_json::json!({
            "latitude": lat,
            "longitude": lng
        })),
        None => HttpResponse::NotFound().json(serde_json::json!({
            "error": "노드를 찾을 수 없습니다."
        })),
    }
}

/// node_id로 건물 폴리곤 중심 좌표 조회
///
/// GET /api/navigation/polygon_center/{node_id}
#[get("/api/navigation/polygon_center/{node_id}")]
pub async fn get_polygon_center(node_id: web::Path<String>) -> impl Responder {
    let node_id = node_id.into_inner();
    log::info!("폴리곤 중심 조회: {}", node_id);

    let coords = node_coordinates();
    match coords.get(node_id.as_str()) {
        Some(&(lat, lng)) => HttpResponse::Ok().json(serde_json::json!({
            "latitude": lat,
            "longitude": lng
        })),
        None => HttpResponse::NotFound().json(serde_json::json!({
            "error": "건물을 찾을 수 없습니다."
        })),
    }
}

/// 경로 계산 API
///
/// POST /api/navigation/route
#[post("/api/navigation/route")]
pub async fn calculate_route(body: web::Json<RouteRequest>) -> impl Responder {
    let request = body.into_inner();
    log::info!(
        "경로 계산 요청: ({}, {}) -> ({}, {})",
        request.start.latitude,
        request.start.longitude,
        request.end.latitude,
        request.end.longitude,
    );

    let mock_route = RouteResponse {
        duration: "0분".to_string(),
        distance: "0.0km".to_string(),
        route: vec![
            Coordinate {
                latitude: request.start.latitude,
                longitude: request.start.longitude,
            },
            Coordinate {
                latitude: request.end.latitude,
                longitude: request.end.longitude,
            },
        ],
        warnings: vec!["경로 계산 알고리즘 미연동 - 직선 경로만 표시됩니다.".to_string()],
    };

    HttpResponse::Ok().json(mock_route)
}
