#![allow(unexpected_cfgs)]

use flutter_rust_bridge::frb;

#[derive(Debug)]
#[frb(dart_metadata=("freezed"))]
pub struct Metadata {
    pub title: Option<String>,
    pub artist: Option<String>,
    pub album: Option<String>,
    pub album_artist: Option<String>,
    pub track_number: Option<u8>,
    pub track_total: Option<u8>,
    pub disc_number: Option<u8>,
    pub disc_total: Option<u8>,
    pub date: Option<String>,
    pub genre: Option<String>,
    pub front_cover: Option<Vec<u8>>,
}

impl Metadata {
    pub(crate) const fn new() -> Self {
        Self {
            title: None,
            artist: None,
            album: None,
            album_artist: None,
            track_number: None,
            track_total: None,
            disc_number: None,
            disc_total: None,
            date: None,
            genre: None,
            front_cover: None,
        }
    }
}

#[derive(Debug, Clone)]
#[frb(dart_metadata=("freezed"))]
pub struct Properties {
    pub duration_sec: Option<f64>,
    pub cue_start_sec: Option<f64>,
    pub cue_duration_sec: Option<f64>,
    pub codec: Option<String>,
    pub sample_format: Option<String>,
    pub sample_rate: Option<u32>,
    pub bits_per_raw_sample: Option<u8>,
    pub bits_per_coded_sample: Option<u8>,
    pub bit_rate: Option<u32>,
    pub channels: Option<u8>,
}

impl Properties {
    pub(crate) const fn new() -> Self {
        Self {
            duration_sec: None,
            cue_start_sec: None,
            cue_duration_sec: None,
            codec: None,
            sample_format: None,
            sample_rate: None,
            bits_per_raw_sample: None,
            bits_per_coded_sample: None,
            bit_rate: None,
            channels: None,
        }
    }
}
