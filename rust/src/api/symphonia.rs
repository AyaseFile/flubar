use crate::api::models::{Metadata, Properties};
use anyhow::{anyhow, Result};
use std::{fs, path};
use symphonia::core::audio::AudioBufferRef;
use symphonia::core::codecs::{DecoderOptions, CODEC_TYPE_NULL};
use symphonia::core::formats::FormatOptions;
use symphonia::core::io::MediaSourceStream;
use symphonia::core::meta::{MetadataOptions, StandardTagKey, StandardVisualKey};
use symphonia::core::probe::Hint;
use symphonia::default::{get_codecs, get_probe};

pub fn read_file(file: String) -> Result<(Metadata, Properties)> {
    let path = path::Path::new(&file);

    let src = fs::File::open(path).map_err(|e| anyhow!("Failed to open file: {:?}", e))?;
    let mss = MediaSourceStream::new(Box::new(src), Default::default());

    let mut hint = Hint::new();
    if let Some(extension) = path.extension() {
        if let Some(ext_str) = extension.to_str() {
            hint.with_extension(ext_str);
        }
    }

    let meta_opts: MetadataOptions = Default::default();
    let fmt_opts: FormatOptions = Default::default();
    let probed = get_probe()
        .format(&hint, mss, &fmt_opts, &meta_opts)
        .map_err(|e| anyhow!("Unsupported format: {:?}", e))?;

    let mut format = probed.format;

    let mut metadata = Metadata::new();
    let mut properties = Properties::new();

    if let Some(meta) = format.metadata().current() {
        for tag in meta.tags().iter() {
            if tag.is_known() {
                match tag.std_key {
                    Some(StandardTagKey::TrackTitle) => {
                        metadata.title = Some(tag.value.to_string());
                    }
                    Some(StandardTagKey::Artist) => {
                        metadata.artist = Some(tag.value.to_string());
                    }
                    Some(StandardTagKey::Album) => {
                        metadata.album = Some(tag.value.to_string());
                    }
                    Some(StandardTagKey::AlbumArtist) => {
                        metadata.album_artist = Some(tag.value.to_string());
                    }
                    Some(StandardTagKey::Date) => {
                        metadata.date = Some(tag.value.to_string());
                    }
                    Some(StandardTagKey::Genre) => {
                        metadata.genre = Some(tag.value.to_string());
                    }
                    Some(StandardTagKey::TrackNumber) => {
                        if let Ok(num) = tag.value.to_string().parse::<u8>() {
                            metadata.track_number = Some(num);
                        }
                    }
                    Some(StandardTagKey::TrackTotal) => {
                        if let Ok(num) = tag.value.to_string().parse::<u8>() {
                            metadata.track_total = Some(num);
                        }
                    }
                    Some(StandardTagKey::DiscNumber) => {
                        if let Ok(num) = tag.value.to_string().parse::<u8>() {
                            metadata.disc_number = Some(num);
                        }
                    }
                    Some(StandardTagKey::DiscTotal) => {
                        if let Ok(num) = tag.value.to_string().parse::<u8>() {
                            metadata.disc_total = Some(num);
                        }
                    }
                    _ => {}
                }
            }
        }

        for visual in meta.visuals() {
            if let Some(StandardVisualKey::FrontCover) = visual.usage {
                metadata.front_cover = Some(visual.data.to_vec());
                break;
            }
        }
    }

    let track = format
        .tracks()
        .iter()
        .find(|t| t.codec_params.codec != CODEC_TYPE_NULL)
        .ok_or_else(|| anyhow!("No supported audio track found"))?;

    let track_id = track.id;
    let codec_params = &track.codec_params;

    if let Some(codec_desc) = get_codecs().get_codec(codec_params.codec) {
        properties.codec = Some(codec_desc.short_name.to_string());
    } else {
        properties.codec = Some(format!("{:?}", codec_params.codec));
    }

    if let Some(sample_rate) = codec_params.sample_rate {
        properties.sample_rate = Some(sample_rate);
    }

    if let Some(channels) = codec_params.channels {
        properties.channels = Some(channels.count() as u8);
    }

    if let Some(bits_per_sample) = codec_params.bits_per_sample {
        properties.bits_per_raw_sample = Some(bits_per_sample as u8);
    }

    if let Some(bits_per_coded_sample) = codec_params.bits_per_coded_sample {
        properties.bits_per_coded_sample = Some(bits_per_coded_sample as u8);
    }

    if let Some(n_frames) = codec_params.n_frames {
        if let Some(sample_rate) = codec_params.sample_rate {
            properties.duration_sec = Some(n_frames as f64 / sample_rate as f64);
        }
    }

    let dec_opts: DecoderOptions = Default::default();
    let mut decoder = get_codecs()
        .make(codec_params, &dec_opts)
        .map_err(|e| anyhow!("Unsupported codec: {:?}", e))?;

    let mut total_bytes = 0;

    while let Ok(packet) = format.next_packet() {
        if packet.track_id() == track_id {
            total_bytes += packet.data.len();
            if properties.sample_format.is_none() {
                if let Ok(decoded) = decoder.decode(&packet) {
                    properties.sample_format = Some(get_sample_format(decoded));
                }
            }
        }
    }

    if let Some(duration) = properties.duration_sec {
        if duration > 0.0 {
            properties.bit_rate = Some((total_bytes as f64 / duration * 8.0) as u32);
        }
    }

    Ok((metadata, properties))
}

pub fn cue_read_properties(file: String) -> Result<Properties> {
    let path = path::Path::new(&file);

    let src = fs::File::open(path).map_err(|e| anyhow!("Failed to open file: {:?}", e))?;
    let mss = MediaSourceStream::new(Box::new(src), Default::default());

    let mut hint = Hint::new();
    if let Some(extension) = path.extension() {
        if let Some(ext_str) = extension.to_str() {
            hint.with_extension(ext_str);
        }
    }

    let meta_opts: MetadataOptions = Default::default();
    let fmt_opts: FormatOptions = Default::default();
    let probed = get_probe()
        .format(&hint, mss, &fmt_opts, &meta_opts)
        .map_err(|e| anyhow!("Unsupported format: {:?}", e))?;

    let mut format = probed.format;

    let mut properties = Properties::new();

    let track = format
        .tracks()
        .iter()
        .find(|t| t.codec_params.codec != CODEC_TYPE_NULL)
        .ok_or_else(|| anyhow!("No supported audio track found"))?;

    let track_id = track.id;
    let codec_params = &track.codec_params;

    if let Some(codec_desc) = get_codecs().get_codec(codec_params.codec) {
        properties.codec = Some(codec_desc.short_name.to_string());
    } else {
        properties.codec = Some(format!("{:?}", codec_params.codec));
    }

    if let Some(sample_rate) = codec_params.sample_rate {
        properties.sample_rate = Some(sample_rate);
    }

    if let Some(channels) = codec_params.channels {
        properties.channels = Some(channels.count() as u8);
    }

    if let Some(bits_per_sample) = codec_params.bits_per_sample {
        properties.bits_per_raw_sample = Some(bits_per_sample as u8);
    }

    if let Some(bits_per_coded_sample) = codec_params.bits_per_coded_sample {
        properties.bits_per_coded_sample = Some(bits_per_coded_sample as u8);
    }

    if let Some(n_frames) = codec_params.n_frames {
        if let Some(sample_rate) = codec_params.sample_rate {
            properties.duration_sec = Some(n_frames as f64 / sample_rate as f64);
        }
    }

    let dec_opts: DecoderOptions = Default::default();
    let mut decoder = get_codecs()
        .make(codec_params, &dec_opts)
        .map_err(|e| anyhow!("Unsupported codec: {:?}", e))?;

    let mut total_bytes = 0;

    while let Ok(packet) = format.next_packet() {
        if packet.track_id() == track_id {
            total_bytes += packet.data.len();
            if properties.sample_format.is_none() {
                if let Ok(decoded) = decoder.decode(&packet) {
                    properties.sample_format = Some(get_sample_format(decoded));
                }
            }
        }
    }

    if let Some(duration) = properties.duration_sec {
        if duration > 0.0 {
            properties.bit_rate = Some((total_bytes as f64 / duration * 8.0) as u32);
        }
    }

    Ok(properties)
}

fn get_sample_format(buffer: AudioBufferRef<'_>) -> String {
    match buffer {
        AudioBufferRef::U8(_) => "u8".to_string(),
        AudioBufferRef::U16(_) => "u16".to_string(),
        AudioBufferRef::U24(_) => "u24".to_string(),
        AudioBufferRef::U32(_) => "u32".to_string(),
        AudioBufferRef::S8(_) => "s8".to_string(),
        AudioBufferRef::S16(_) => "s16".to_string(),
        AudioBufferRef::S24(_) => "s24".to_string(),
        AudioBufferRef::S32(_) => "s32".to_string(),
        AudioBufferRef::F32(_) => "f32".to_string(),
        AudioBufferRef::F64(_) => "f64".to_string(),
    }
}
