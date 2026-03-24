use actix_web::web;
use crate::handlers::{location, place, navigation};

pub fn init_routes(cfg: &mut web::ServiceConfig) {
    cfg
        // 위치 API
        .service(location::get_current_location)
        // 장소 검색 API
        .service(place::search_places)
        .service(place::search_places_by_category)
        .service(place::get_place_by_node_id)
        // 경로 안내 API
        .service(navigation::get_node_coordinates)
        .service(navigation::get_polygon_center)
        .service(navigation::calculate_route)
        // 헬스체크
        .service(location::health_check);
}
