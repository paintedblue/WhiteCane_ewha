use actix_web::{get, web, HttpResponse, Responder};
use serde::{Deserialize, Serialize};
use std::env;

#[derive(Serialize)]
pub struct PlaceResponse {
    pub name: String,
    pub address: String,
    pub latitude: f64,
    pub longitude: f64,
    pub category: String,
    pub phone_number: Option<String>,
}

#[derive(Deserialize)]
pub struct SearchQuery {
    pub name: Option<String>,
}

// Kakao Local Search API 응답 구조체
#[derive(Deserialize)]
struct KakaoSearchResponse {
    documents: Vec<KakaoDocument>,
}

#[derive(Deserialize)]
struct KakaoDocument {
    place_name: String,
    address_name: String,
    road_address_name: String,
    x: String, // longitude
    y: String, // latitude
    category_group_name: String,
    phone: String,
}

/// 장소 검색 (Kakao Local Search API 사용)
///
/// GET /api/building?name={name}
#[get("/api/building")]
pub async fn search_places(query: web::Query<SearchQuery>) -> impl Responder {
    let search_term = match &query.name {
        Some(name) if !name.is_empty() => name.clone(),
        _ => return HttpResponse::Ok().json(Vec::<PlaceResponse>::new()),
    };

    log::info!("장소 검색: {}", search_term);

    let kakao_api_key = env::var("KAKAO_REST_API_KEY").unwrap_or_default();

    let client = reqwest::Client::new();
    let resp = client
        .get("https://dapi.kakao.com/v2/local/search/keyword.json")
        .header("Authorization", format!("KakaoAK {}", kakao_api_key))
        .query(&[("query", &search_term), ("size", &"15".to_string())])
        .send()
        .await;

    match resp {
        Ok(r) => {
            let text = r.text().await.unwrap_or_default();
            log::info!("Kakao 검색 원본 응답: {}", text);
            match serde_json::from_str::<KakaoSearchResponse>(&text) {
                Ok(result) => {
                    let results: Vec<PlaceResponse> = result
                        .documents
                        .into_iter()
                        .filter_map(|doc| {
                            let lat = doc.y.parse::<f64>().ok()?;
                            let lng = doc.x.parse::<f64>().ok()?;
                            Some(PlaceResponse {
                                name: doc.place_name,
                                address: if doc.road_address_name.is_empty() {
                                    doc.address_name
                                } else {
                                    doc.road_address_name
                                },
                                latitude: lat,
                                longitude: lng,
                                category: doc.category_group_name,
                                phone_number: if doc.phone.is_empty() {
                                    None
                                } else {
                                    Some(doc.phone)
                                },
                            })
                        })
                        .collect();
                    HttpResponse::Ok().json(results)
                }
                Err(e) => {
                    log::error!("Kakao 응답 파싱 실패: {} | 원본: {}", e, text);
                    HttpResponse::Ok().json(Vec::<PlaceResponse>::new())
                }
            }
        }
        Err(e) => {
            log::error!("Kakao API 호출 실패: {}", e);
            HttpResponse::InternalServerError().json(serde_json::json!({
                "error": "검색 서비스에 연결할 수 없습니다."
            }))
        }
    }
}
