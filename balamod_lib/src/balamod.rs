use std::path::{Path, PathBuf};
use std::fs::File;
use std::fs;
use zip::ZipArchive;
use std::io::{BufReader, Write, Read, Cursor};
use zip::{ZipWriter, CompressionMethod, write::FileOptions};
use libflate::deflate::Encoder;
use crate::luas::get_mod_core;
use log::{error, info};

#[cfg(target_os = "windows")]
use winreg::enums::*;
#[cfg(target_os = "windows")]
use winreg::RegKey;

#[derive(Clone)]
pub struct Balatro {
    pub path: PathBuf,
    pub version: String,
}

impl Balatro {
    pub fn get_exe_path_buf(&self) -> PathBuf {
        add_executable_to_path(self.path.clone())
    }

    pub fn replace_file(&self, file_name: &str, new_contents: &[u8]) -> Result<(), std::io::Error> {
        let exe_path_buf = self.get_exe_path_buf();
        let exe_path = exe_path_buf.to_str().expect("Failed to convert exe_path to str");
        replace_file_in_exe(exe_path, file_name, new_contents)
    }

    pub fn get_file_data(&self, file_name: &str) -> Result<Vec<u8>, std::io::Error> {
        let exe_path_buf = self.get_exe_path_buf();
        let exe_path = exe_path_buf.to_str().expect("Failed to convert exe_path to str");
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
        error!("'{}' not found in the archive.", file_name);
        Ok(Vec::new())
    }

    pub fn get_all_files(&self) -> Result<Vec<String>, std::io::Error> {
        let exe_path_buf = self.get_exe_path_buf();
        let exe_path = exe_path_buf.to_str().expect("Failed to convert exe_path to str");
        let file = File::open(exe_path)?;
        let mut archive = ZipArchive::new(BufReader::new(file))?;

        let mut files = Vec::new();
        for i in 0..archive.len() {
            let file = archive.by_index(i)?;
            files.push(file.name().to_string());
        }
        Ok(files)
    }


    pub fn get_file_as_string(&self, file_name: &str, decompress: bool) -> Result<String, std::io::Error> {
        let data = self.get_file_data(file_name)?;
        if decompress {
            let decompressed = decompress_bytes(&data)?;
            Ok(String::from_utf8(decompressed).unwrap())
        } else {
            Ok(String::from_utf8(data).unwrap())
        }
    }

    pub fn get_all_lua_files(&self) -> Result<Vec<String>, std::io::Error> {
        let exe_path_buf = self.get_exe_path_buf();
        let exe_path = exe_path_buf.to_str().expect("Failed to convert exe_path to str");
        let file = File::open(exe_path)?;
        let mut archive = ZipArchive::new(BufReader::new(file))?;

        let mut lua_files = Vec::new();
        for i in 0..archive.len() {
            let file = archive.by_index(i)?;
            if file.name().ends_with(".lua") {
                lua_files.push(file.name().to_string());
            }
        }
        Ok(lua_files)
    }

    pub fn build_mod_core(&self) -> Result<String, std::io::Error> {
        let paths = self.get_all_lua_files()?;
        let loader = get_mod_core().to_string();
        let mut path_string = String::new();
        for path in paths {
            path_string.push_str(&format!("    \"{}\",\n", path));
        }
        path_string.pop();
        path_string.pop();
        let loader = loader.replace("{paths}", &format!("{}", path_string));
        Ok(loader)
    }
}

fn add_executable_to_path(path: PathBuf) -> PathBuf {
    if cfg!(target_os = "windows") || cfg!(target_os = "linux") {
        return path.join("Balatro.exe");
    }
    return path.join("Balatro.app/Contents/Resources/Balatro.love");
}

#[cfg(target_os = "windows")]
fn read_path_from_registry() -> Result<String, std::io::Error> {
    let hklm = RegKey::predef(HKEY_LOCAL_MACHINE);
    let steam_path = hklm.open_subkey("SOFTWARE\\WOW6432Node\\Valve\\Steam")?;

    Ok(steam_path.get_value("InstallPath")?)
}

// for other OSs
#[cfg(not(target_os = "windows"))]
fn read_path_from_registry() -> Result<String, std::io::Error> {
    Ok("".to_string())
}

pub fn find_balatros() -> Vec<Balatro> {
    let mut paths: Vec<PathBuf> = Vec::new();
    if cfg!(target_os = "windows") {
        let steam_path = read_path_from_registry();
        let mut steam_path = steam_path.unwrap_or_else(|_| {
            error!("Could not read steam install path from Registry! Trying standard installation path in C:\\");
            "C:\\Program Files (x86)\\Steam".to_owned()
        });

        steam_path.push_str("\\steamapps\\libraryfolders.vdf");
        let libraryfolders_path = Path::new(&steam_path);
        if !libraryfolders_path.exists() {
            error!("'{}' not found.", libraryfolders_path.to_str().unwrap());
            return vec![];
        }

        let libraryfolders_file = File::open(libraryfolders_path).expect("Failed to open libraryfolders.vdf");
        let mut libraryfolders_contents = String::new();
        let mut libraryfolders_reader = BufReader::new(libraryfolders_file);
        libraryfolders_reader.read_to_string(&mut libraryfolders_contents).expect("Failed to read libraryfolders.vdf");

        let libraryfolders_contents = libraryfolders_contents.split("\n").collect::<Vec<&str>>();
        let mut libraryfolders_contents = libraryfolders_contents.iter();
        while let Some(line) = libraryfolders_contents.next() {
            if line.contains("\t\t\"path\"\t\t") {
                let path = line.split("\"").collect::<Vec<&str>>()[3];
                paths.push(PathBuf::from(path).join("steamapps\\common\\Balatro"));
            }
        }
    } else if cfg!(target_os = "linux") {
        match home::home_dir() {
            Some(path) => {
                let mut path = path;
                path.push(".local/share/Steam/steamapps/common/Balatro");
                paths.push(path);
            }
            None => error!("Impossible to get your home dir!"),
        }
    } else if cfg!(target_os = "macos") {
        match home::home_dir() {
            Some(path) => {
                let mut path = path;
                path.push("Library/Application Support/Steam/steamapps/common/Balatro");
                paths.push(path);
            }
            None => error!("Impossible to get your home dir!"),
        }
    }

    remove_unexisting_paths(&mut paths);

    let mut balatros = Vec::new();
    for path in paths {
        let exe_path = add_executable_to_path(path.clone());
        info!("Checking {}", exe_path.to_str().unwrap());
        if !exe_path.exists() {
            continue;
        }
        let version = get_balatro_version(exe_path.to_str().unwrap()).expect("Error while getting Balatro version");
        balatros.push(Balatro {
            path,
            version,
        });
    }

    balatros
}

fn remove_unexisting_paths(paths: &mut Vec<PathBuf>) {
    let mut i = 0;
    while i < paths.len() {
        if !paths[i].exists() {
            paths.remove(i);
        } else {
            i += 1;
        }
    }
    info!("Found {} Balatro installations.", paths.len());
}

fn get_balatro_version(exe_path: &str) -> Result<String, std::io::Error> {
    let file = File::open(exe_path)?;
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
    error!("'version.jkr' not found in the archive.");
    Ok("0.0.0".to_string())
}

fn replace_file_in_exe(exe_path: &str, file_name: &str, new_contents: &[u8]) -> Result<(), std::io::Error> {
    let mut exe_data = fs::read(exe_path)?;

    let zip_start = find_zip_start(&exe_data).unwrap();
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

        zip_writer.start_file(file_name, FileOptions::default().compression_method(CompressionMethod::Stored))?;
        zip_writer.write_all(new_contents)?;

        zip_writer.finish()?;
    }

    exe_data.splice(zip_start.., new_zip.into_iter());
    fs::write(exe_path, exe_data)?;
    Ok(())
}

fn find_zip_start(exe_data: &[u8]) -> Result<usize, &'static str> {
    let zip_signature: [u8; 4] = [0x50, 0x4b, 0x03, 0x04];
    exe_data.windows(4).position(|window| window == zip_signature)
        .ok_or("ZIP start not found")
}

#[allow(dead_code)]
fn copy_dir_all(src: impl AsRef<Path>, dst: impl AsRef<Path>) -> std::io::Result<()> {
    fs::create_dir_all(&dst)?;
    for entry in fs::read_dir(src)? {
        let entry = entry?;
        let ty = entry.file_type()?;
        if ty.is_dir() {
            copy_dir_all(entry.path(), dst.as_ref().join(entry.file_name()))?;
        } else {
            fs::copy(entry.path(), dst.as_ref().join(entry.file_name()))?;
        }
    }
    Ok(())
}

pub fn compress_file(input_path: &str, output_path: &str) -> Result<(), std::io::Error> {
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

pub fn decompress_bytes(input: &[u8]) -> Result<Vec<u8>, std::io::Error> {
    let mut decoder = libflate::deflate::Decoder::new(input);
    let mut decompressed = Vec::new();
    decoder.read_to_end(&mut decompressed)?;
    Ok(decompressed)
}