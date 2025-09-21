use std::ffi::CStr;

use anyhow::Result;
use ffmpeg_next as ffmpeg;

use super::models::Properties;

pub fn init_ffmpeg() {
    ffmpeg::init().unwrap();
}

pub(crate) fn read_properties(file: &str) -> Result<Properties> {
    let mut context = ffmpeg::format::input(file)?;

    let mut properties = Properties::new();

    if let Some(stream) = context.streams().best(ffmpeg::media::Type::Audio) {
        let params = stream.parameters();

        properties.duration_sec = Some(stream.duration() as f64 * f64::from(stream.time_base()));
        properties.codec = Some(params.id().name().to_string());

        unsafe {
            let params_ptr = params.as_ptr();
            let sample_format =
                ffmpeg::ffi::av_get_sample_fmt_name(std::mem::transmute::<
                    i32,
                    ffmpeg::ffi::AVSampleFormat,
                >((*params_ptr).format));
            let sample_rate = (*params_ptr).sample_rate;
            let bits_per_raw_sample = (*params_ptr).bits_per_raw_sample;
            let bits_per_coded_sample = (*params_ptr).bits_per_coded_sample;
            let bit_rate = (*params_ptr).bit_rate;
            let channels = (*params_ptr).ch_layout.nb_channels;

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

        if properties.bit_rate.is_none() && properties.duration_sec.is_some() {
            let audio_stream_index = stream.index();
            let mut total_bytes = 0;
            for (stream, packet) in context.packets() {
                if stream.index() == audio_stream_index {
                    total_bytes += packet.size();
                }
            }
            let duration = properties.duration_sec.unwrap();
            properties.bit_rate = Some((total_bytes as f64 / duration * 8.0) as u32);
        }
    }

    Ok(properties)
}
