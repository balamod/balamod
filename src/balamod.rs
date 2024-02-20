use std::path::{Path, PathBuf};
use std::fs::File;
use std::fs;
use zip::ZipArchive;
use std::io::{BufReader, Write, Read, Cursor};
use colour::red_ln;
use zip::{ZipWriter, CompressionMethod, write::FileOptions};
use libflate::deflate::Encoder;

#[derive(Clone)]
pub struct Balatro {
    pub(crate) path: PathBuf,
    pub(crate) version: String,
}

impl Balatro {
    pub fn replace_file(&self, file_name: &str, new_contents: &[u8]) -> Result<(), std::io::Error> {
        let exe_path_buf = self.path.join("Balatro.exe");
        let exe_path = exe_path_buf.to_str().expect("Failed to convert exe_path to str");
        replace_file_in_exe(exe_path, file_name, new_contents)
    }

    pub fn get_file_data(&self, file_name: &str) -> Result<Vec<u8>, std::io::Error>{
        let exe_path_buf = self.path.join("Balatro.exe");
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
        red_ln!("'{}' not found in the archive.", file_name);
        Ok(Vec::new())
    }
}


pub fn find_balatros() -> Vec<Balatro> {
    let mut paths: Vec<PathBuf> = Vec::new();
    if cfg!(target_os = "windows") {
        let libraryfolders_path = Path::new("C:\\Program Files (x86)\\Steam\\steamapps\\libraryfolders.vdf");
        if !libraryfolders_path.exists() {
            red_ln!("'{}' not found.", libraryfolders_path.to_str().unwrap());
            return vec![]
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
            None => red_ln!("Impossible to get your home dir!"),
        }
    }

    remove_unexisting_paths(&mut paths);

    let mut balatros = Vec::new();
    for path in paths {
        let exe_path = path.clone().join("Balatro.exe");
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
    red_ln!("'version.jkr' not found in the archive.");
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
            let mut file = zip_archive.by_index(i)?;
            if file.name() != file_name {
                let options = FileOptions::default()
                    .compression_method(file.compression())
                    .unix_permissions(file.unix_mode().unwrap_or(0o755));

                zip_writer.start_file(file.name(), options)?;
                let mut file_contents = Vec::new();
                file.read_to_end(&mut file_contents)?;
                zip_writer.write_all(&file_contents)?;
            }
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