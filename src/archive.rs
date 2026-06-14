use textfmt::*;
use std::{
    io::{ Read, Write, },
    path::Path,
};

use crate::Error;

pub mod zip_utils {
    use super::*;
    pub fn replace_file(
        exe_path: &Path,
        file_name: &str,
        new_contents: &[u8],
    ) -> Result<(), Error> {
        let exe_data = std::fs::read(exe_path)?;
        let zip_start = exe_data
            .windows(4)
            .position(|window| window == [0x50, 0x4b, 0x03, 0x04])
            .ok_or("ZIP start not found")?;
        let mut reader = zip::ZipArchive::new(std::io::Cursor::new(&exe_data[zip_start..]))?;
        let mut buffer = Vec::from(&exe_data[0..zip_start]);
        buffer.reserve(4096);
        let mut writer = zip::ZipWriter::new(std::io::Cursor::new(&mut buffer[zip_start..]));
        for name in reader.file_names()
            .filter(|&name| name != file_name)
            .map(|name| name.to_string())
            .collect::<Vec<_>>() 
        {
            writer.raw_copy_file(reader.by_name(&name)?)?;
        }
        drop(reader);

        writer.start_file(
            file_name, 
            zip::write::SimpleFileOptions::default()
                .compression_method(zip::CompressionMethod::Stored))?;
        writer.write_all(new_contents)?;
        writer.finish()?;

        std::fs::write(exe_path, buffer)?;
        Ok(())
    }

    pub fn extract_all(game_path: &Path, output_path: &Path) -> Result<(), Error> {
        Ok(
            zip::ZipArchive::new(std::fs::File::open(crate::paths::get_exe_path(game_path))?)?
                .extract(output_path)?
        )
    }

    pub fn get_version(path: &Path) -> Result<String, Error> {
        Ok(String::from_utf8(
                zip::ZipArchive::new(std::fs::File::open(crate::paths::get_exe_path(path))?)?
                .by_name("version.jkr")?
                .bytes()
                .map(|x| x.unwrap_or(0))
                .collect())?
            .lines()
            .nth(1)
            .unwrap_or_else(|| {
                "'version.jkr' not found in the archive."
                    .red()
                    .italic()
                    .println();
                return "0.0.0";
            })
            .to_string())
    }

    pub fn compress_file(input_path: &Path, output_path: &Path) -> Result<(), Error> {
        let mut buf = Vec::<u8>::with_capacity(4096);
        flate2::read::DeflateEncoder::new(
            std::fs::File::open(input_path)?, 
            flate2::Compression::default())
            .read_to_end(&mut buf)?;
        Ok(std::fs::write(output_path, buf)?)
    }
}

pub mod tar_utils {
    use super::*;
    pub fn unpack_tar(dir: &str, tar: Vec<u8>, linux_native: bool) -> Result<(), Error> {
        tar::Archive::new(flate2::read::GzDecoder::new(std::io::Cursor::new(tar)))
            .unpack(dir)?;
        let dir_path = std::path::PathBuf::from(dir);
        std::fs::rename(
            dir_path.join(crate::dependencies::get_tar_file_name(linux_native).split('.').next().unwrap()), 
            dir_path.join("balamod"))?; // rename dir to balamod
        Ok(())
    }
}
