use std::path::Path;
use std::str::FromStr;

use anyhow::Result;
use id3::{Tag, TagLike, Timestamp};

use super::models::Metadata;

pub fn id3_write_metadata(file: String, metadata: Metadata) -> Result<()> {
    let path = Path::new(&file);
    let mut tag = Tag::read_from_path(path)?;

    if let Some(title) = metadata.title {
        tag.set_title(title);
    } else {
        tag.remove_title();
    }

    if let Some(album) = metadata.album {
        tag.set_album(album);
    } else {
        tag.remove_album();
    }

    if let Some(album_artist) = metadata.album_artist {
        tag.set_album_artist(album_artist);
    } else {
        tag.remove_album_artist();
    }

    if let Some(artist) = metadata.artist {
        tag.set_artist(artist);
    } else {
        tag.remove_artist();
    }

    if let Some(track_number) = metadata.track_number {
        tag.set_track(track_number as u32);
    } else {
        tag.remove_track();
    }

    if let Some(track_total) = metadata.track_total {
        tag.set_total_tracks(track_total as u32);
    } else {
        tag.remove_total_tracks();
    }

    if let Some(disc_number) = metadata.disc_number {
        tag.set_disc(disc_number as u32);
    } else {
        tag.remove_disc();
    }

    if let Some(disc_total) = metadata.disc_total {
        tag.set_total_discs(disc_total as u32);
    } else {
        tag.remove_total_discs();
    }

    if let Some(date) = metadata.date {
        tag.set_date_recorded(Timestamp::from_str(&date).expect("Failed to parse date"));
    } else {
        tag.remove_year();
    }

    if let Some(genre) = metadata.genre {
        tag.set_genre(genre);
    } else {
        tag.remove_genre();
    }

    tag.write_to_path(path, id3::Version::Id3v24)?;
    Ok(())
}

pub fn id3_write_picture(file: String, picture: Option<Vec<u8>>) -> Result<()> {
    let path = Path::new(&file);
    let mut tag = Tag::read_from_path(path)?;

    if let Some(picture) = picture {
        let picture_type = id3::frame::PictureType::CoverFront;
        let kind = infer::get(&picture).expect("Failed to get mime type");
        let mime_type = kind.mime_type();
        let picture = id3::frame::Picture {
            mime_type: mime_type.to_string(),
            picture_type,
            description: String::new(),
            data: picture,
        };
        tag.add_frame(picture);
    } else {
        tag.remove_picture_by_type(id3::frame::PictureType::CoverFront);
    }

    tag.write_to_path(path, id3::Version::Id3v24)?;
    Ok(())
}
