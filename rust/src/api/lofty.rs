use std::str::FromStr;

use anyhow::{Result, anyhow};
use lofty::config::WriteOptions;
use lofty::file::{FileType, TaggedFile, TaggedFileExt};
use lofty::picture::{MimeType, PictureType};
use lofty::prelude::Accessor;
use lofty::properties::FileProperties;
use lofty::tag::items::Timestamp;
use lofty::tag::{ItemKey, Tag, TagExt};

use super::models::{Metadata, Properties};

pub fn write_metadata(
    file: &str,
    metadata: Metadata,
    force: bool,
    write_tags: bool,
    write_cover: bool,
) -> Result<()> {
    let (mut tag, file_type) = if force {
        create_or_get_tag(file)?
    } else {
        try_get_tag(file)?
    };

    let Metadata {
        title,
        artist,
        album,
        album_artist,
        track_number,
        track_total,
        disc_number,
        disc_total,
        date,
        genre,
        front_cover,
    } = metadata;

    if write_tags {
        let is_wavpack = file_type == FileType::WavPack;
        let date_key = if is_wavpack {
            ItemKey::Year
        } else {
            ItemKey::RecordingDate
        };

        fn set_or_remove(tag: &mut Tag, key: ItemKey, value: Option<String>) -> Result<()> {
            match value {
                Some(value) => {
                    if !tag.insert_text(key, value) {
                        return Err(anyhow!("Failed to insert text for key: {:?}", key));
                    }
                }
                None => {
                    tag.remove_key(key);
                }
            }
            Ok(())
        }

        set_or_remove(&mut tag, ItemKey::TrackTitle, title)?;
        set_or_remove(&mut tag, ItemKey::AlbumTitle, album)?;
        set_or_remove(&mut tag, ItemKey::AlbumArtist, album_artist)?;
        set_or_remove(&mut tag, ItemKey::TrackArtist, artist)?;
        set_or_remove(
            &mut tag,
            ItemKey::TrackNumber,
            track_number.map(|n| n.to_string()),
        )?;
        set_or_remove(
            &mut tag,
            ItemKey::TrackTotal,
            track_total.map(|n| n.to_string()),
        )?;
        set_or_remove(
            &mut tag,
            ItemKey::DiscNumber,
            disc_number.map(|n| n.to_string()),
        )?;
        set_or_remove(
            &mut tag,
            ItemKey::DiscTotal,
            disc_total.map(|n| n.to_string()),
        )?;

        set_or_remove(
            &mut tag,
            date_key,
            date.map(|d| {
                Timestamp::from_str(&d)
                    .expect("Failed to parse date")
                    .to_string()
            }),
        )?;

        set_or_remove(&mut tag, ItemKey::Genre, genre)?;
    }

    if write_cover {
        update_front_cover(&mut tag, front_cover)?;
    }

    tag.save_to_path(file, WriteOptions::default())?;
    Ok(())
}

fn update_front_cover(tag: &mut Tag, cover: Option<Vec<u8>>) -> Result<()> {
    match cover {
        Some(data) => {
            let kind = infer::get(&data).expect("Failed to get mime type");
            let mime_type = MimeType::from_str(kind.mime_type());
            let cover_front_index = tag
                .pictures()
                .iter()
                .position(|p| p.pic_type() == PictureType::CoverFront);
            let picture = lofty::picture::Picture::new_unchecked(
                PictureType::CoverFront,
                Some(mime_type),
                None,
                data,
            );
            if let Some(index) = cover_front_index {
                tag.set_picture(index, picture);
            } else {
                tag.push_picture(picture);
            }
        }
        None => {
            tag.remove_picture_type(PictureType::CoverFront);
        }
    }
    Ok(())
}

#[inline]
fn try_get_tag(file: &str) -> Result<(Tag, FileType)> {
    let (tagged_file, file_type) = get_tagged_file(file)?;

    if let Some(primary_tag) = tagged_file.primary_tag() {
        return Ok((primary_tag.to_owned(), file_type));
    }

    tagged_file.first_tag().map_or_else(
        || Err(anyhow!("Failed to get or create tag")),
        |tag| Ok((tag.to_owned(), file_type)),
    )
}

#[inline]
fn create_or_get_tag(file: &str) -> Result<(Tag, FileType)> {
    let (mut tagged_file, file_type) = get_tagged_file(file)?;

    if let Some(primary_tag) = tagged_file.primary_tag() {
        return Ok((primary_tag.to_owned(), file_type));
    }

    if let Some(first_tag) = tagged_file.first_tag() {
        return Ok((first_tag.to_owned(), file_type));
    }

    let tag_type = tagged_file.primary_tag_type();
    tagged_file.insert_tag(Tag::new(tag_type));
    let primary_tag = tagged_file.primary_tag().unwrap();
    Ok((primary_tag.to_owned(), file_type))
}

#[inline]
fn get_tagged_file(file: &str) -> Result<(TaggedFile, FileType)> {
    match lofty::read_from_path(file) {
        Ok(tagged_file) => {
            let file_type = tagged_file.file_type();
            Ok((tagged_file, file_type))
        }
        _ => {
            let prob = lofty::probe::Probe::open(file)?;
            let file_type = prob.file_type().unwrap();
            let tagged_file = TaggedFile::new(file_type, FileProperties::default(), vec![]);
            Ok((tagged_file, file_type))
        }
    }
}

pub(crate) fn read_front_cover(file: &str) -> Result<Option<Vec<u8>>> {
    let tagged_file = lofty::read_from_path(file)?;

    if let Some(tag) = tagged_file
        .primary_tag()
        .or_else(|| tagged_file.first_tag())
        && let Some(cover) = tag
            .get_picture_type(PictureType::CoverFront)
            .or_else(|| tag.pictures().first())
    {
        return Ok(Some(cover.data().to_vec()));
    }

    Ok(None)
}

pub fn read_metadata(file: &str) -> Result<Metadata> {
    let tagged_file = lofty::read_from_path(file)?;

    let mut metadata = Metadata::new();

    let is_wavpack = tagged_file.file_type() == FileType::WavPack;
    let date_key = if is_wavpack {
        ItemKey::Year
    } else {
        ItemKey::RecordingDate
    };

    if let Some(tag) = tagged_file
        .primary_tag()
        .or_else(|| tagged_file.first_tag())
    {
        metadata.title = tag.title().map(|e| e.to_string());
        metadata.artist = tag.artist().map(|e| e.to_string());
        metadata.album = tag.album().map(|e| e.to_string());
        metadata.album_artist = tag.get_string(ItemKey::AlbumArtist).map(|e| e.to_string());
        metadata.track_number = tag.track().map(|e| e as u8);
        metadata.track_total = tag.track_total().map(|e| e as u8);
        metadata.disc_number = tag.disk().map(|e| e as u8);
        metadata.disc_total = tag.disk_total().map(|e| e as u8);
        metadata.date = tag.get_string(date_key).map(|e| e.to_string());
        metadata.genre = tag.genre().map(|e| e.to_string());

        if let Some(cover) = tag
            .get_picture_type(PictureType::CoverFront)
            .or_else(|| tag.pictures().first())
        {
            metadata.front_cover = Some(cover.data().to_vec());
        }
    }

    Ok(metadata)
}

pub fn read_hybrid(file: &str) -> Result<(Metadata, Properties)> {
    let metadata = read_metadata(file)?;
    let properties = super::ffmpeg::read_properties(file)?;
    Ok((metadata, properties))
}
