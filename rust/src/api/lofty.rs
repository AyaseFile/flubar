use std::str::FromStr;

use anyhow::{Result, anyhow};
use lofty::config::WriteOptions;
use lofty::file::{TaggedFile, TaggedFileExt};
use lofty::picture::{MimeType, PictureType};
use lofty::prelude::Accessor;
use lofty::properties::FileProperties;
use lofty::tag::items::Timestamp;
use lofty::tag::{ItemKey, Tag, TagExt};

use super::models::{Metadata, Properties};

pub fn write_metadata(file: &str, metadata: Metadata, force: bool) -> Result<()> {
    let mut tag = if force {
        create_or_get_tag(file)?
    } else {
        try_get_tag(file)?
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

    set_or_remove(&mut tag, ItemKey::TrackTitle, metadata.title)?;
    set_or_remove(&mut tag, ItemKey::AlbumTitle, metadata.album)?;
    set_or_remove(&mut tag, ItemKey::AlbumArtist, metadata.album_artist)?;
    set_or_remove(&mut tag, ItemKey::TrackArtist, metadata.artist)?;
    set_or_remove(
        &mut tag,
        ItemKey::TrackNumber,
        metadata.track_number.map(|n| n.to_string()),
    )?;
    set_or_remove(
        &mut tag,
        ItemKey::TrackTotal,
        metadata.track_total.map(|n| n.to_string()),
    )?;
    set_or_remove(
        &mut tag,
        ItemKey::DiscNumber,
        metadata.disc_number.map(|n| n.to_string()),
    )?;
    set_or_remove(
        &mut tag,
        ItemKey::DiscTotal,
        metadata.disc_total.map(|n| n.to_string()),
    )?;
    set_or_remove(
        &mut tag,
        ItemKey::RecordingDate,
        metadata.date.map(|d| {
            Timestamp::from_str(&d)
                .expect("Failed to parse date")
                .to_string()
        }),
    )?;
    set_or_remove(&mut tag, ItemKey::Genre, metadata.genre)?;

    tag.save_to_path(file, WriteOptions::default())?;
    Ok(())
}

pub fn write_front_cover(file: &str, cover: Option<Vec<u8>>, force: bool) -> Result<()> {
    let mut tag = if force {
        create_or_get_tag(file)?
    } else {
        try_get_tag(file)?
    };

    if let Some(cover) = cover {
        let kind = infer::get(&cover).expect("Failed to get mime type");
        let mime_type = MimeType::from_str(kind.mime_type());
        let cover_front_index = tag
            .pictures()
            .iter()
            .position(|p| p.pic_type() == PictureType::CoverFront);
        let picture = lofty::picture::Picture::new_unchecked(
            PictureType::CoverFront,
            Some(mime_type),
            None,
            cover,
        );
        if let Some(index) = cover_front_index {
            tag.set_picture(index, picture);
        } else {
            tag.push_picture(picture);
        }
    } else {
        tag.remove_picture_type(PictureType::CoverFront);
    }

    tag.save_to_path(file, WriteOptions::default())?;
    Ok(())
}

#[inline]
fn try_get_tag(file: &str) -> Result<Tag> {
    let tagged_file = get_tagged_file(file)?;

    if let Some(primary_tag) = tagged_file.primary_tag() {
        return Ok(primary_tag.to_owned());
    }

    tagged_file.first_tag().map_or_else(
        || Err(anyhow!("Failed to get or create tag")),
        |tag| Ok(tag.to_owned()),
    )
}

#[inline]
fn create_or_get_tag(file: &str) -> Result<Tag> {
    let mut tagged_file = get_tagged_file(file)?;

    if let Some(primary_tag) = tagged_file.primary_tag() {
        return Ok(primary_tag.to_owned());
    }

    if let Some(first_tag) = tagged_file.first_tag() {
        return Ok(first_tag.to_owned());
    }

    let tag_type = tagged_file.primary_tag_type();
    tagged_file.insert_tag(Tag::new(tag_type));
    let primary_tag = tagged_file.primary_tag().unwrap();
    Ok(primary_tag.to_owned())
}

#[inline]
fn get_tagged_file(file: &str) -> Result<TaggedFile> {
    match lofty::read_from_path(file) {
        Ok(tagged_file) => Ok(tagged_file),
        _ => {
            let prob = lofty::probe::Probe::open(file)?;
            Ok(TaggedFile::new(
                prob.file_type().unwrap(),
                FileProperties::default(),
                vec![],
            ))
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

pub fn read_hybrid(file: &str) -> Result<(Metadata, Properties)> {
    let tagged_file = lofty::read_from_path(file)?;

    let mut metadata = Metadata::new();

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
        metadata.date = tag
            .get_string(ItemKey::RecordingDate)
            .map(|e| e.to_string());
        metadata.genre = tag.genre().map(|e| e.to_string());

        if let Some(cover) = tag
            .get_picture_type(PictureType::CoverFront)
            .or_else(|| tag.pictures().first())
        {
            metadata.front_cover = Some(cover.data().to_vec());
        }
    }

    let properties = super::ffmpeg::read_properties(file)?;

    Ok((metadata, properties))
}
