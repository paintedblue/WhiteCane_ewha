use actix_web::{get, web, HttpResponse, Responder};
use serde::{Deserialize, Serialize};

#[derive(Serialize)]
pub struct PlaceResponse {
    pub building_id: i32,
    pub node_id: String,
    pub name: String,
    pub alias: String,
    pub category: String,
    pub address: String,
    pub phone_number: Option<String>,
}

#[derive(Serialize)]
pub struct PlaceDetailResponse {
    pub building: PlaceResponse,
    pub ramps: Vec<RampResponse>,
    pub disabled_restrooms: Vec<RestroomResponse>,
    pub elevators: Vec<ElevatorResponse>,
}

#[derive(Serialize)]
pub struct RampResponse {
    pub ramp_id: i32,
    pub building_id: i32,
    pub node_id: String,
    pub floor: i32,
    pub location_description: String,
}

#[derive(Serialize)]
pub struct RestroomResponse {
    pub restroom_id: i32,
    pub building_id: i32,
    pub node_id: String,
    pub floor: i32,
    pub location_description: String,
}

#[derive(Serialize)]
pub struct ElevatorResponse {
    pub elevator_id: i32,
    pub building_id: i32,
    pub node_id: String,
    pub location_description: String,
}

#[derive(Deserialize)]
pub struct SearchQuery {
    pub name: Option<String>,
    pub category: Option<String>,
}

/// 장소 이름으로 검색
///
/// GET /api/building?name={name}
///
/// TODO: 데이터베이스 연동 시 실제 쿼리로 교체
#[get("/api/building")]
pub async fn search_places(query: web::Query<SearchQuery>) -> impl Responder {
    let search_term = query.name.as_deref().unwrap_or("").to_string();
    log::info!("장소 검색: {}", search_term);

    // TODO: 데이터베이스에서 장소 검색
    // 현재는 빈 목록 반환
    let results: Vec<PlaceResponse> = vec![];
    HttpResponse::Ok().json(results)
}

/// 카테고리로 장소 검색
///
/// GET /api/building/category?category={category}
///
/// TODO: 데이터베이스 연동 시 실제 쿼리로 교체
#[get("/api/building/category")]
pub async fn search_places_by_category(query: web::Query<SearchQuery>) -> impl Responder {
    let category = query.category.as_deref().unwrap_or("").to_string();
    log::info!("카테고리 검색: {}", category);

    // TODO: 데이터베이스에서 카테고리 필터 검색
    let results: Vec<PlaceResponse> = vec![];
    HttpResponse::Ok().json(results)
}

/// node_id로 장소 상세 조회
///
/// GET /api/buildings_node/{node_id}
///
/// TODO: 데이터베이스 연동 시 실제 쿼리로 교체
#[get("/api/buildings_node/{node_id}")]
pub async fn get_place_by_node_id(node_id: web::Path<String>) -> impl Responder {
    let node_id = node_id.into_inner();
    log::info!("장소 상세 조회: {}", node_id);

    // TODO: 데이터베이스에서 node_id로 장소 조회
    HttpResponse::NotFound().json(serde_json::json!({
        "error": "TODO: 데이터베이스 연동 후 구현"
    }))
}
