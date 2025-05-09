use std::ffi::CStr;

use anyhow::{anyhow, Result};
use ffmpeg_next as ffmpeg;
use ffmpeg_next::ffi::av_get_sample_fmt_name;

use super::models::{Metadata, Properties};

pub fn init_ffmpeg() -> Result<()> {
    ffmpeg::init().map_err(|e| anyhow!("Failed to initialize FFmpeg: {:?}", e))
}

pub fn read_file(file: String) -> Result<(Metadata, Properties)> {
    let mut context = match ffmpeg::format::input(&file) {
        Ok(context) => context,
        Err(e) => return Err(anyhow!("Failed to open file: {:?}", e)),
    };

    let format = &context.format();
    let format_name = format.name();
    let dict_ref = &context.metadata();

    let mut metadata = Metadata::new();
    let mut properties = Properties::new();

    if let Some(title) = get_metadata_value(dict_ref, "title") {
        metadata.title = Some(title);
    }

    if let Some(artist) = get_metadata_value(dict_ref, "artist") {
        metadata.artist = Some(artist);
    }

    if let Some(album) = get_metadata_value(dict_ref, "album") {
        metadata.album = Some(album);
    }

    if let Some(album_artist) = get_metadata_value(dict_ref, "album_artist") {
        metadata.album_artist = Some(album_artist);
    }

    if let Some(date) = get_metadata_value(dict_ref, "date") {
        metadata.date = Some(date);
    }

    if let Some(genre) = get_metadata_value(dict_ref, "genre") {
        metadata.genre = Some(genre);
    }

    match format_name {
        "mp3" | "wav" => {
            if let Some(track) = get_metadata_value(dict_ref, "track") {
                let (track_number, track_total) = parse_number_total(&track);
                metadata.track_number = track_number;
                metadata.track_total = track_total;
            }

            if let Some(disc) = get_metadata_value(dict_ref, "disc") {
                let (disc_number, disc_total) = parse_number_total(&disc);
                metadata.disc_number = disc_number;
                metadata.disc_total = disc_total;
            }
        }
        "flac" => {
            if let Some(tracknumber) = get_metadata_value(dict_ref, "tracknumber") {
                metadata.track_number = tracknumber.parse().ok();
            } else if let Some(track) = get_metadata_value(dict_ref, "track") {
                metadata.track_number = track.parse().ok();
            }

            if let Some(totaltracks) = get_metadata_value(dict_ref, "totaltracks") {
                metadata.track_total = totaltracks.parse().ok();
            } else if let Some(totaltracks) = get_metadata_value(dict_ref, "tracktotal") {
                metadata.track_total = totaltracks.parse().ok();
            }

            if let Some(discnumber) = get_metadata_value(dict_ref, "discnumber") {
                metadata.disc_number = discnumber.parse().ok();
            } else if let Some(disc) = get_metadata_value(dict_ref, "disc") {
                metadata.disc_number = disc.parse().ok();
            }

            if let Some(totaldiscs) = get_metadata_value(dict_ref, "totaldiscs") {
                metadata.disc_total = totaldiscs.parse().ok();
            } else if let Some(totaldiscs) = get_metadata_value(dict_ref, "disctotal") {
                metadata.disc_total = totaldiscs.parse().ok();
            }
        }
        _ => {}
    }

    let video_stream = context
        .streams()
        .best(ffmpeg::media::Type::Video)
        .map(|stream| stream.index());
    let audio_stream = context
        .streams()
        .best(ffmpeg::media::Type::Audio)
        .map(|stream| stream.index());

    let mut total_bytes = 0;
    for (stream, packet) in context.packets() {
        if video_stream.is_some() && stream.index() == video_stream.unwrap() {
            if let Some(data) = packet.data() {
                metadata.front_cover = Some(data.to_vec());
            }
        }
        if audio_stream.is_some() && stream.index() == audio_stream.unwrap() {
            total_bytes += packet.size();
        }
    }

    if let Some(stream_index) = audio_stream {
        let stream = context.stream(stream_index).unwrap();
        properties.duration_sec = Some(stream.duration() as f64 * f64::from(stream.time_base()));
        let codec = ffmpeg::codec::context::Context::from_parameters(stream.parameters())?;
        if let Ok(audio) = codec.decoder().audio() {
            unsafe {
                let audio_ptr = audio.as_ptr();
                let codec_id = (*audio_ptr).codec_id;
                let codec = ffmpeg::codec::id::Id::from(codec_id);
                let sample_format = av_get_sample_fmt_name((*audio_ptr).sample_fmt);
                let sample_rate = (*audio_ptr).sample_rate;
                let bits_per_raw_sample = (*audio_ptr).bits_per_raw_sample;
                let bits_per_coded_sample = (*audio_ptr).bits_per_coded_sample;
                let bit_rate = (*audio_ptr).bit_rate;
                let channels = (*audio_ptr).ch_layout.nb_channels;

                properties.codec = Some(codec.name().to_string());
                properties.sample_format = (!sample_format.is_null())
                    .then(|| CStr::from_ptr(sample_format).to_string_lossy().into_owned());
                properties.sample_rate = (sample_rate != 0).then_some(sample_rate as u32);
                properties.bits_per_raw_sample =
                    (bits_per_raw_sample != 0).then_some(bits_per_raw_sample as u8);
                properties.bits_per_coded_sample =
                    (bits_per_coded_sample != 0).then_some(bits_per_coded_sample as u8);
                properties.bit_rate = (bit_rate != 0).then_some(bit_rate as u32);
                properties.channels = (channels != 0).then_some(channels as u8);
            }
        }

        if properties.bit_rate.is_none() && properties.duration_sec.is_some() {
            let duration = properties.duration_sec.unwrap();
            properties.bit_rate = Some((total_bytes as f64 / duration * 8.0) as u32);
        }
    }

    Ok((metadata, properties))
}

pub(crate) fn cue_read_properties(file: String) -> Result<Properties> {
    let mut context = match ffmpeg::format::input(&file) {
        Ok(context) => context,
        Err(e) => return Err(anyhow!("Failed to open file: {:?}", e)),
    };

    let mut properties = Properties::new();

    if let Some(stream) = context.streams().best(ffmpeg::media::Type::Audio) {
        let audio_stream = stream.index();
        properties.duration_sec = Some(stream.duration() as f64 * f64::from(stream.time_base()));
        let codec = ffmpeg::codec::context::Context::from_parameters(stream.parameters())?;
        if let Ok(audio) = codec.decoder().audio() {
            unsafe {
                let audio_ptr = audio.as_ptr();
                let codec_id = (*audio_ptr).codec_id;
                let codec = ffmpeg::codec::id::Id::from(codec_id);
                let sample_format = av_get_sample_fmt_name((*audio_ptr).sample_fmt);
                let sample_rate = (*audio_ptr).sample_rate;
                let bits_per_raw_sample = (*audio_ptr).bits_per_raw_sample;
                let bits_per_coded_sample = (*audio_ptr).bits_per_coded_sample;
                let bit_rate = (*audio_ptr).bit_rate;
                let channels = (*audio_ptr).ch_layout.nb_channels;

                properties.codec = Some(codec.name().to_string());
                properties.sample_format = (!sample_format.is_null())
                    .then(|| CStr::from_ptr(sample_format).to_string_lossy().into_owned());
                properties.sample_rate = (sample_rate != 0).then_some(sample_rate as u32);
                properties.bits_per_raw_sample =
                    (bits_per_raw_sample != 0).then_some(bits_per_raw_sample as u8);
                properties.bits_per_coded_sample =
                    (bits_per_coded_sample != 0).then_some(bits_per_coded_sample as u8);
                properties.bit_rate = (bit_rate != 0).then_some(bit_rate as u32);
                properties.channels = (channels != 0).then_some(channels as u8);
            }
        }

        if properties.bit_rate.is_none() && properties.duration_sec.is_some() {
            let mut total_bytes = 0;
            for (stream, packet) in context.packets() {
                if stream.index() == audio_stream {
                    total_bytes += packet.size();
                }
            }
            let duration = properties.duration_sec.unwrap();
            properties.bit_rate = Some((total_bytes as f64 / duration * 8.0) as u32);
        }
    }

    Ok(properties)
}

pub(crate) fn cue_read_front_cover(file: String) -> Result<Option<Vec<u8>>> {
    let mut context = match ffmpeg::format::input(&file) {
        Ok(context) => context,
        Err(e) => return Err(anyhow!("Failed to open file: {:?}", e)),
    };

    let video_stream = context
        .streams()
        .best(ffmpeg::media::Type::Video)
        .map(|stream| stream.index());

    for (stream, packet) in context.packets() {
        if video_stream.is_some() && stream.index() == video_stream.unwrap() {
            if let Some(data) = packet.data() {
                return Ok(Some(data.to_vec()));
            }
        }
    }

    Ok(None)
}

#[inline]
fn get_metadata_value(dict: &ffmpeg::dictionary::Ref, key: &str) -> Option<String> {
    dict.get(key)
        .map(|s| String::from_utf8_lossy(s.as_bytes()).into_owned())
        .or_else(|| {
            dict.get(&key.to_uppercase())
                .map(|s| String::from_utf8_lossy(s.as_bytes()).into_owned())
        })
}

#[inline]
fn parse_number_total(value: &str) -> (Option<u8>, Option<u8>) {
    if let Some((number, total)) = value.split_once('/') {
        (number.parse().ok(), total.parse().ok())
    } else {
        (value.parse().ok(), None)
    }
}
