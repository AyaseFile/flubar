use crate::api::ffmpeg::cue_read_properties;
use crate::api::models::{Metadata, Properties};
use anyhow::{anyhow, Context, Result};
use cue::cd::CD;
use cue::cd_text::PTI;

const REM_DATE: usize = 0;
const FPS: f64 = 75.0;

pub fn cue_read_file(file: String) -> Result<Vec<(String, Metadata, Properties)>> {
    let cue_sheet = std::fs::read_to_string(file.clone())?;
    let cd = CD::parse(cue_sheet).map_err(|e| anyhow!("Failed to parse cue sheet: {:?}", e))?;

    let album = cd.get_cdtext().read(PTI::Title);
    let album_artist = cd.get_cdtext().read(PTI::Performer);
    let date = cd.get_rem().read(REM_DATE);
    let track_total = cd.get_track_count() as u8;
    let genre = cd.get_cdtext().read(PTI::Genre);

    let mut properties_map: std::collections::HashMap<String, Properties> =
        std::collections::HashMap::new();
    let mut result: Vec<(String, Metadata, Properties)> = Vec::new();
    let dir = std::path::Path::new(&file)
        .parent()
        .context("Failed to get parent directory")?;

    for (index, track) in cd.tracks().iter().enumerate() {
        let filename = track.get_filename();
        let path = dir.join(&filename);
        let path_str = path.to_string_lossy().to_string();
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
            front_cover: None,
        };

        let properties = if let Some(properties) = properties_map.get(&filename) {
            properties.clone()
        } else {
            let properties = cue_read_properties(path_str.clone())?;
            properties_map.insert(filename.clone(), properties.clone());
            properties
        };

        let cue_start = track.get_start() as f64 / FPS;
        let cue_duration = if let Some(duration) = track.get_length() {
            Some(duration as f64 / FPS)
        } else if let Some(total_duration) = properties.duration_sec {
            let start_time = track.get_start() as f64 / FPS;
            Some(total_duration - start_time)
        } else {
            None
        };

        let properties = Properties {
            duration_sec: None,
            cue_start_sec: Some(cue_start),
            cue_duration_sec: cue_duration,
            codec: properties.codec.clone(),
            sample_format: properties.sample_format.clone(),
            sample_rate: properties.sample_rate,
            bits_per_raw_sample: properties.bits_per_raw_sample,
            bits_per_coded_sample: properties.bits_per_coded_sample,
            bit_rate: properties.bit_rate,
            channels: properties.channels,
        };

        result.push((path_str, metadata, properties));
    }

    Ok(result)
}