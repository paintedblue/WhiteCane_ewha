use actix_web::{get, post, web, HttpResponse, Responder};
use serde::{Deserialize, Serialize};

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

/// node_id로 포인트 좌표 조회
///
/// GET /api/navigation/node_coordinates/{node_id}
///
/// TODO: 데이터베이스(PostGIS)에서 OSM 노드 좌표 조회로 교체
#[get("/api/navigation/node_coordinates/{node_id}")]
pub async fn get_node_coordinates(node_id: web::Path<String>) -> impl Responder {
    let node_id = node_id.into_inner();
    log::info!("노드 좌표 조회: {}", node_id);

    // TODO: 데이터베이스에서 node_id에 해당하는 좌표 조회
    // SELECT ST_Y(ST_Transform(way, 4326)) AS latitude,
    //        ST_X(ST_Transform(way, 4326)) AS longitude
    // FROM planet_osm_point WHERE osm_id = $1
    HttpResponse::NotFound().json(serde_json::json!({
        "error": "TODO: 데이터베이스 연동 후 구현"
    }))
}

/// node_id로 건물 폴리곤 중심 좌표 조회
///
/// GET /api/navigation/polygon_center/{node_id}
///
/// TODO: 데이터베이스(PostGIS)에서 건물 폴리곤 중심 계산으로 교체
#[get("/api/navigation/polygon_center/{node_id}")]
pub async fn get_polygon_center(node_id: web::Path<String>) -> impl Responder {
    let node_id = node_id.into_inner();
    log::info!("폴리곤 중심 조회: {}", node_id);

    // TODO: 데이터베이스에서 건물 폴리곤 중심 계산
    // SELECT ST_Y(ST_Centroid(ST_Transform(way, 4326))) AS latitude,
    //        ST_X(ST_Centroid(ST_Transform(way, 4326))) AS longitude
    // FROM planet_osm_polygon WHERE osm_id = $1
    HttpResponse::NotFound().json(serde_json::json!({
        "error": "TODO: 데이터베이스 연동 후 구현"
    }))
}

/// 경로 계산 API
///
/// POST /api/navigation/route
///
/// TODO: 경로 계산 엔진(Valhalla, OSRM 등) 연동으로 교체
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

    // TODO: 경로 계산 엔진 연동
    // - Valhalla: POST http://valhalla_server:8002/route
    // - OSRM: GET http://osrm_server:5000/route/v1/...
    // - 기타 라우팅 서버 연동
    //
    // 현재는 직선 경로(출발지->목적지)만 반환합니다.
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
