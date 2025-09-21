use std::{collections::HashMap, fs::read_to_string, path::Path};

use anyhow::Result;
use cue::cd::CD;
use cue::cd_text::PTI;

use super::ffmpeg::read_properties;
use super::lofty::read_front_cover;
use super::models::{Metadata, Properties};

pub const REM_DATE: usize = 0;
pub const FPS: f64 = 75.0;

pub fn cue_read_file(file: &str) -> Result<Vec<(String, Metadata, Properties)>> {
    let cue_sheet = read_to_string(file)?;
    let cd = CD::parse(cue_sheet)?;

    let album = cd.get_cdtext().read(PTI::Title);
    let album_artist = cd.get_cdtext().read(PTI::Performer);
    let date = cd.get_rem().read(REM_DATE);
    let track_total = cd.get_track_count() as u8;
    let genre = cd.get_cdtext().read(PTI::Genre);

    let mut properties_map: HashMap<String, Properties> = HashMap::new();
    let mut front_cover_map: HashMap<String, Option<Vec<u8>>> = HashMap::new();
    let mut result: Vec<(String, Metadata, Properties)> = Vec::new();
    let dir = Path::new(file).parent().unwrap();

    for (index, track) in cd.tracks().into_iter().enumerate() {
        let filename = track.get_filename();
        let path = dir.join(&filename).to_string_lossy().into_owned();

        let properties = if let Some(properties) = properties_map.get(&filename) {
            properties.clone()
        } else {
            let properties = read_properties(&path)?;
            properties_map.insert(filename.clone(), properties.clone());
            properties
        };

        let front_cover = if let Some(front_cover) = front_cover_map.get(&filename) {
            front_cover.clone()
        } else {
            let front_cover = read_front_cover(&path)?;
            front_cover_map.insert(filename, front_cover.clone());
            front_cover
        };

        let title = track.get_cdtext().read(PTI::Title);
        let artist = track.get_cdtext().read(PTI::Performer);
        let track_number = (index as u8) + 1;
        let metadata = Metadata {
            title,
            artist,
            album: album.clone(),
            album_artist: album_artist.clone(),
            track_number: Some(track_number),
            track_total: Some(track_total),
            disc_number: None,
            disc_total: None,
            date: date.clone(),
            genre: genre.clone(),
            front_cover,
        };

        let cue_start = track.get_start() as f64 / FPS;
        let cue_duration = if let Some(duration) = track.get_length() {
            Some(duration as f64 / FPS)
        } else {
            properties.duration_sec.map(|duration| duration - cue_start)
        };

        let properties = Properties {
            duration_sec: None,
            cue_start_sec: Some(cue_start),
            cue_duration_sec: cue_duration,
            codec: properties.codec,
            sample_format: properties.sample_format,
            sample_rate: properties.sample_rate,
            bits_per_raw_sample: properties.bits_per_raw_sample,
            bits_per_coded_sample: properties.bits_per_coded_sample,
            bit_rate: properties.bit_rate,
            channels: properties.channels,
        };

        result.push((path, metadata, properties));
    }

    Ok(result)
}
