use std::str::FromStr;

use anyhow::{anyhow, Result};
use lofty::config::WriteOptions;
use lofty::file::{TaggedFile, TaggedFileExt};
use lofty::picture::{MimeType, PictureType};
use lofty::properties::FileProperties;
use lofty::tag::items::Timestamp;
use lofty::tag::{ItemKey, Tag, TagExt};

use super::models::Metadata;

pub fn lofty_write_metadata(file: String, metadata: Metadata, force: bool) -> Result<()> {
    let mut tag = if force {
        force_create_tag_for_file(&file)?
    } else {
        get_or_create_tag_for_file(&file)?
    };

    fn set_or_remove(tag: &mut Tag, key: ItemKey, value: Option<String>) -> Result<()> {
        match value {
            Some(v) => {
                if !tag.insert_text(key.clone(), v) {
                    return Err(anyhow!("Failed to insert text for key: {:?}", key));
                }
            }
            None => {
                tag.remove_key(&key);
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

    tag.save_to_path(&file, WriteOptions::default())?;
    Ok(())
}

pub fn lofty_write_picture(file: String, picture: Option<Vec<u8>>, force: bool) -> Result<()> {
    let mut tag = if force {
        force_create_tag_for_file(&file)?
    } else {
        get_or_create_tag_for_file(&file)?
    };

    if let Some(picture) = picture {
        let kind = infer::get(&picture).expect("Failed to get mime type");
        let mime_type = MimeType::from_str(kind.mime_type());
        let cover_front_index = tag
            .pictures()
            .iter()
            .position(|p| p.pic_type() == PictureType::CoverFront);
        let new_picture = lofty::picture::Picture::new_unchecked(
            PictureType::CoverFront,
            Some(mime_type),
            None,
            picture,
        );
        if let Some(index) = cover_front_index {
            tag.set_picture(index, new_picture);
        } else {
            tag.push_picture(new_picture);
        }
    } else {
        tag.remove_picture_type(PictureType::CoverFront);
    }

    tag.save_to_path(&file, WriteOptions::default())?;
    Ok(())
}

#[inline]
fn get_or_create_tag_for_file(file: &str) -> Result<Tag> {
    let tagged_file = get_tagged_file(file)?;

    if let Some(primary_tag) = tagged_file.primary_tag() {
        return Ok(primary_tag.to_owned());
    }

    tagged_file.first_tag().map_or_else(
        || Err(anyhow!("Failed to get or create tag")),
        |first_tag| Ok(first_tag.to_owned()),
    )
}

#[inline]
fn force_create_tag_for_file(file: &str) -> Result<Tag> {
    let mut tagged_file = get_tagged_file(file)?;

    if let Some(primary_tag) = tagged_file.primary_tag_mut() {
        return Ok(primary_tag.to_owned());
    }

    if let Some(first_tag) = tagged_file.first_tag_mut() {
        return Ok(first_tag.to_owned());
    }

    let tag_type = tagged_file.primary_tag_type();
    tagged_file.insert_tag(Tag::new(tag_type));
    let primary_tag = tagged_file.primary_tag_mut().unwrap();
    Ok(primary_tag.to_owned())
}

#[inline]
fn get_tagged_file(file: &str) -> Result<TaggedFile> {
    match lofty::read_from_path(file) {
        Ok(tagged_file) => Ok(tagged_file),
        _ => {
            let prob = lofty::probe::Probe::open(file)?;
            if prob.file_type().is_none() {
                return Err(anyhow!("File type could not be determined"));
            }
            Ok(TaggedFile::new(
                prob.file_type().unwrap(),
                FileProperties::default(),
                vec![],
            ))
        }
    }
}
