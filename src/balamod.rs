use crate::dependencies::*;
use crate::finder::get_balatro_paths;
use colour::red_ln;
use libflate::deflate::Encoder;
use std::fs;
use std::fs::File;
use std::io::{BufReader, Cursor, Read, Write};
use std::path::{Path, PathBuf};
use zip::ZipArchive;
use zip::{write::FileOptions, CompressionMethod, ZipWriter};

#[derive(Clone)]
pub struct Balatro {
    pub(crate) path: PathBuf,
}

impl Balatro {
    #[cfg(target_os = "macos")]
    pub fn get_exe_path(&self) -> PathBuf {
        return self.path.clone().join("Balatro.app/Contents/Resources/Balatro.love");
    }
    #[cfg(target_os = "windows")]
    pub fn get_exe_path(&self) -> PathBuf {
        return self.path.clone().join("Balatro.exe");
    }
    #[cfg(target_os = "linux")]
    pub fn get_exe_path(&self) -> PathBuf {
        return self.path.clone().join("Balatro.exe");
    }

    fn inject_common_dependencies(&self, exe_path: &str, balamod_version: &'static str) -> Result<(), std::io::Error> {
        self.add_file_in_exe(exe_path, get_balamod_lua().as_bytes().to_vec(), "balamod.lua")?;
        self.add_file_in_exe(exe_path, get_mod_menu_lua().as_bytes().to_vec(), "mod_menu.lua")?;
        self.add_file_in_exe(exe_path, get_logging_lua().as_bytes().to_vec(), "logging.lua")?;
        self.add_file_in_exe(exe_path, get_platform_lua().as_bytes().to_vec(), "platform.lua")?;
        self.add_file_in_exe(exe_path, get_console_lua().as_bytes().to_vec(), "console.lua")?;
        self.add_file_in_exe(exe_path, get_joker_api_lua().as_bytes().to_vec(), "jokerapi.lua")?;
        self.add_file_in_exe(exe_path, get_balamod_version_lua(balamod_version).as_bytes().to_vec(), "balamod_version.lua")?;
        self.add_file_in_exe(exe_path, get_patches_lua().as_bytes().to_vec(), "patches.lua")?;
        self.add_file_in_exe(exe_path, get_json_lua().as_bytes().to_vec(), "json.lua")?;
        self.add_file_in_exe(exe_path, get_utils_lua().as_bytes().to_vec(), "utils.lua")?;
        self.add_file_in_exe(exe_path, get_tar_lua().as_bytes().to_vec(), "tar.lua")?;
        self.add_file_in_exe(exe_path, get_mod_api_lua().as_bytes().to_vec(), "mod.lua")?;
        self.add_file_in_exe(exe_path, get_assets_lua().as_bytes().to_vec(), "assets.lua")?;
        Ok(())
    }

    #[cfg(target_os = "macos")]
    pub fn inject_dependencies(&self, balamod_version: &'static str) -> Result<(), std::io::Error> {
        let exe_path_buf = self.get_exe_path();
        let exe_path = exe_path_buf
            .to_str()
            .expect("Failed to convert exe_path to str");
        self.copy_file_in_resources(exe_path_buf.parent().unwrap(), get_https_so(), "https.so")?;
        self.inject_common_dependencies(exe_path, balamod_version)?;
        Ok(())
    }

    #[cfg(any(target_os = "windows", target_os = "linux"))]
    pub fn inject_dependencies(&self, balamod_version: &'static str) -> Result<(), std::io::Error> {
        let exe_path_buf = self.get_exe_path();
        let exe_path = exe_path_buf
            .to_str()
            .expect("Failed to convert exe_path to str");
        self.copy_file_in_resources(exe_path_buf.parent().unwrap(), get_https_so(), "https.dll")?;
        self.inject_common_dependencies(exe_path, balamod_version)?;
        Ok(())
    }

    #[cfg(target_os = "macos")]
    pub fn remove_dependencies(&self) -> Result<(), std::io::Error> {
        let exe_path_buf = self.get_exe_path();
        let resource_dir = exe_path_buf.parent().unwrap();
        fs::remove_file(resource_dir.join("https.so"))?;
        Ok(())
    }

    #[cfg(any(target_os = "windows", target_os = "linux"))]
    pub fn remove_dependencies(&self) -> Result<(), std::io::Error> {
        let exe_path_buf = self.get_exe_path();
        let resource_dir = exe_path_buf.parent().unwrap();
        fs::remove_file(resource_dir.join("https.dll"))?;
        Ok(())
    }

    pub fn replace_file(&self, file_name: &str, new_contents: &[u8]) -> Result<(), std::io::Error> {
        let exe_path_buf = self.get_exe_path();
        let exe_path = exe_path_buf
            .to_str()
            .expect("Failed to convert exe_path to str");
        self.replace_file_in_exe(exe_path, file_name, new_contents)
    }

    pub fn get_file_data(&self, file_name: &str) -> Result<Vec<u8>, std::io::Error> {
        let exe_path_buf = self.get_exe_path();
        let exe_path = exe_path_buf
            .to_str()
            .expect("Failed to convert exe_path to str");
        let file = File::open(exe_path)?;
        let mut archive = ZipArchive::new(BufReader::new(file))?;

        for i in 0..archive.len() {
            let mut file = archive.by_index(i)?;
            if file.name() == file_name {
                let mut contents = Vec::new();
                file.read_to_end(&mut contents)?;
                return Ok(contents);
            }
        }
        red_ln!("'{}' not found in the archive.", file_name);
        Ok(Vec::new())
    }

    pub fn get_all_files(&self) -> Result<Vec<String>, std::io::Error> {
        let exe_path_buf = self.get_exe_path();
        let exe_path = exe_path_buf
            .to_str()
            .expect("Failed to convert exe_path to str");
        let file = File::open(exe_path)?;
        let mut archive = ZipArchive::new(BufReader::new(file))?;

        let mut files = Vec::new();
        for i in 0..archive.len() {
            let file = archive.by_index(i)?;
            files.push(file.name().to_string());
        }
        Ok(files)
    }

    pub fn get_file_as_string(
        &self,
        file_name: &str,
        decompress: bool,
    ) -> Result<String, std::io::Error> {
        let data = self.get_file_data(file_name)?;
        if decompress {
            let decompressed = self.decompress_bytes(&data)?;
            Ok(String::from_utf8(decompressed).unwrap())
        } else {
            Ok(String::from_utf8(data).unwrap())
        }
    }

    pub fn get_version(&self) -> Result<String, std::io::Error> {
        let file = File::open(self.get_exe_path())?;
        let mut archive = ZipArchive::new(BufReader::new(file))?;

        for i in 0..archive.len() {
            let mut file = archive.by_index(i)?;
            if file.name() == "version.jkr" {
                let mut contents = String::new();
                file.read_to_string(&mut contents)?;
                let version = contents.lines().nth(1).unwrap().to_string();
                return Ok(version);
            }
        }
        red_ln!("'version.jkr' not found in the archive.");
        Ok("0.0.0".to_string())
    }

    fn copy_file_in_resources(
        &self,
        dst: &Path,
        file_data: &[u8],
        file_name: &str,
    ) -> Result<(), std::io::Error> {
        let mut file = File::create(dst.join(file_name))?;
        file.write_all(file_data)?;
        Ok(())
    }

    fn add_file_in_exe(
        &self,
        exe_path: &str,
        file_data: Vec<u8>,
        file_dst: &str,
    ) -> Result<(), std::io::Error> {
        let mut exe_data = fs::read(exe_path)?;

        let zip_start = self.find_zip_start(&exe_data).unwrap();
        let cursor = Cursor::new(&exe_data[zip_start..]);

        let mut zip_archive = ZipArchive::new(cursor)?;
        let mut new_zip = Vec::new();

        {
            let mut zip_writer = ZipWriter::new(Cursor::new(&mut new_zip));

            for i in 0..zip_archive.len() {
                let raw_file = zip_archive.by_index_raw(i)?;
                zip_writer.raw_copy_file(raw_file)?;
            }
            zip_writer.start_file(
                file_dst,
                FileOptions::default().compression_method(CompressionMethod::Stored),
            )?;
            zip_writer.write_all(&file_data)?;

            zip_writer.finish()?;
        }

        exe_data.splice(zip_start.., new_zip.into_iter());
        fs::write(exe_path, exe_data)?;
        Ok(())
    }

    fn replace_file_in_exe(
        &self,
        exe_path: &str,
        file_name: &str,
        new_contents: &[u8],
    ) -> Result<(), std::io::Error> {
        let mut exe_data = fs::read(exe_path)?;

        let zip_start = self.find_zip_start(&exe_data).unwrap();
        let cursor = Cursor::new(&exe_data[zip_start..]);

        let mut zip_archive = ZipArchive::new(cursor)?;
        let mut new_zip = Vec::new();

        {
            let mut zip_writer = ZipWriter::new(Cursor::new(&mut new_zip));

            for i in 0..zip_archive.len() {
                let raw_file = zip_archive.by_index_raw(i)?;

                if raw_file.name() == file_name {
                    continue;
                }

                zip_writer.raw_copy_file(raw_file)?;
            }

            zip_writer.start_file(
                file_name,
                FileOptions::default().compression_method(CompressionMethod::Stored),
            )?;
            zip_writer.write_all(new_contents)?;

            zip_writer.finish()?;
        }

        exe_data.splice(zip_start.., new_zip.into_iter());
        fs::write(exe_path, exe_data)?;
        Ok(())
    }

    fn find_zip_start(&self, exe_data: &[u8]) -> Result<usize, &'static str> {
        let zip_signature: [u8; 4] = [0x50, 0x4b, 0x03, 0x04];
        exe_data
            .windows(4)
            .position(|window| window == zip_signature)
            .ok_or("ZIP start not found")
    }

    #[allow(dead_code)]
    fn copy_dir_all(&self, src: impl AsRef<Path>, dst: impl AsRef<Path>) -> std::io::Result<()> {
        fs::create_dir_all(&dst)?;
        for entry in fs::read_dir(src)? {
            let entry = entry?;
            let ty = entry.file_type()?;
            if ty.is_dir() {
                self.copy_dir_all(entry.path(), dst.as_ref().join(entry.file_name()))?;
            } else {
                fs::copy(entry.path(), dst.as_ref().join(entry.file_name()))?;
            }
        }
        Ok(())
    }

    pub fn compress_file(&self, input_path: &str, output_path: &str) -> Result<(), std::io::Error> {
        // Open the input file for reading
        let mut input_file = File::open(input_path)?;
        let mut buffer = Vec::new();

        // Read the contents of the input file into a buffer
        input_file.read_to_end(&mut buffer)?;

        // Create a new encoder and pass the input data to it
        let mut encoder = Encoder::new(Vec::new());
        encoder.write_all(&buffer)?;

        // Finish the encoding process and retrieve the compressed data
        let compressed = encoder.finish().into_result()?;

        // Create and write the compressed data into the output file
        let mut output_file = File::create(output_path)?;
        output_file.write_all(&compressed)?;

        Ok(())
    }

    pub fn decompress_bytes(&self, input: &[u8]) -> Result<Vec<u8>, std::io::Error> {
        let mut decoder = libflate::deflate::Decoder::new(input);
        let mut decompressed = Vec::new();
        decoder.read_to_end(&mut decompressed)?;
        Ok(decompressed)
    }

    pub fn is_valid(&self) -> bool {
        return self.get_exe_path().exists()
    }
}


pub fn find_balatros() -> Vec<Balatro> {
    let paths: Vec<PathBuf> = get_balatro_paths();
    let mut balatros = Vec::new();
    for path in paths {
        let balatro = Balatro { path };
        if balatro.is_valid() {
            balatros.push(balatro);
        }
    }
    balatros
}
