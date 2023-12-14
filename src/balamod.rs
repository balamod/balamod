use std::path::{Path, PathBuf};
use std::fs::File;
use std::fs;
use zip::ZipArchive;
use std::io::{BufReader, Write, Read, Cursor, BufRead};
use colour::{blue, cyan, green_ln, red_ln, yellow_ln};
use zip::{ZipWriter, CompressionMethod, write::FileOptions};

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

    pub fn extract_ressource_pack(&self, output_folder: &str, textures: bool, shaders: bool, sounds: bool, fonts: bool) -> Result<(), std::io::Error> {
        if PathBuf::from(output_folder).exists() {
            yellow_ln!("{} already exists, deleting it...", output_folder);
            fs::remove_dir_all(output_folder)?;
        }

        let exe_path_buf = self.path.join("Balatro.exe");
        let exe_path = exe_path_buf.to_str().expect("Failed to convert exe_path to str");
        let file = File::open(exe_path)?;
        let mut archive = ZipArchive::new(BufReader::new(file))?;

        for i in 0..archive.len() {
            let mut file = archive.by_index(i)?;
            let file_name = file.name().to_string();
            if file_name.ends_with(".DS_Store") {
                continue;
            }

            if textures && file_name.starts_with("resources/textures/") ||
                shaders && file_name.starts_with("resources/shaders/") ||
                sounds && file_name.starts_with("resources/sounds/") ||
                fonts && file_name.starts_with("resources/fonts/")
            {
                let mut contents = Vec::new();
                file.read_to_end(&mut contents)?;
                let mut path = PathBuf::from(output_folder);
                path.push(file_name.strip_prefix("resources/").unwrap());

                if file_name.ends_with('/') {
                    fs::create_dir_all(&path)?;
                } else {
                    if let Some(parent) = path.parent() {
                        fs::create_dir_all(parent)?;
                    }
                    fs::write(path, contents)?;
                }
            }
        }

        if textures {
            let resizes = vec![1, 2, 4, 8];
            let mut resizes_textures_path = Vec::new();
            for resize in &resizes {
                let mut path = PathBuf::from(output_folder);
                path.push(format!("textures/{}x", resize));
                resizes_textures_path.push(path);
            }

            let mut delete_textures_path = Vec::new();
            for _ in resizes {
                delete_textures_path.push(Vec::new());
            }

            let mut index = 0;
            for path in &resizes_textures_path {
                let files = fs::read_dir(&path)?;

                for file in files {
                    let file = file?;
                    let file_name = file.file_name();
                    let file_name = file_name.to_str().unwrap();

                    for i in index+1..resizes_textures_path.len() {
                        let mut path = resizes_textures_path[i].clone();
                        path.push(file_name);

                        if path.exists() {
                            fs::remove_file(path.clone())?;
                            delete_textures_path[i].push(file_name.to_string());
                        }
                    }
                }
                index += 1;
            }

            for i in 1..delete_textures_path.len() {
                let mut path = resizes_textures_path[i].clone();
                path.push("deleted_textures.txt");
                let mut file = File::create(path)?;
                for file_name in &delete_textures_path[i] {
                    file.write_all(file_name.as_bytes())?;
                    file.write_all(b"\n")?;
                }
            }
        }

        Ok(())
    }

    pub fn apply_built_ressource_pack(&self, build_pack_folder: &str) -> Result<(), std::io::Error> {
        let mut files = Vec::new();
        let mut dirs = Vec::new();
        let mut index = 0;

        dirs.push(PathBuf::from(build_pack_folder));

        while index < dirs.len() {
            let dir = dirs[index].clone();
            let entries = fs::read_dir(dir)?;
            for entry in entries {
                let entry = entry?;
                let path = entry.path();
                if path.is_dir() {
                    dirs.push(path);
                } else {
                    files.push(path);
                }
            }
            index += 1;
        }

        let total = files.len();
        let mut done = 0;

        blue!("\r{}", done);
        cyan!("/");
        blue!("{}", total);
        cyan!(" files patched");
        std::io::stdout().flush().unwrap();
        
        for file in files {
            let cloned_file = file.clone();
            let file_path = cloned_file.strip_prefix(build_pack_folder).unwrap();

            let content_vec = fs::read(&cloned_file)?;
            let content = content_vec.as_slice();

            self.replace_file(format!("resources/{}", file_path.to_str().unwrap()).as_str(), content)?;

            done += 1;

            blue!("\r{}", done);
            cyan!("/");
            blue!("{}", total);
            cyan!(" files patched");
            std::io::stdout().flush().unwrap();
        }
        green_ln!("\r{} files patched                    ", total);
        Ok(())
    }
}


pub fn find_balatros() -> Vec<Balatro> {
    let mut paths = Vec::new();
    if cfg!(target_os = "windows") {
        todo!("Detect windows paths");
    } else if cfg!(target_os = "linux") {
        match home::home_dir() {
            Some(path) => {
                let mut path = path;
                path.push(".local/share/Steam/steamapps/common/Balatro Demo");
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

    let mut zip_archive = zip::ZipArchive::new(cursor)?;
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

pub fn build_textures(input_folder: &str, output_folder: &str) {
    if PathBuf::from(output_folder).exists() {
        fs::remove_dir_all(output_folder).expect("Error while removing output_folder");
    }
    copy_dir_all(input_folder, output_folder).expect("Error while copying input_folder to output_folder");

    let resizes = vec![1, 2, 4, 8];
    let mut resizes_textures_path = Vec::new();
    for resize in &resizes {
        let mut path = PathBuf::from(output_folder);
        path.push(format!("textures/{}x", resize));
        resizes_textures_path.push(path);
    }

    let mut index = 0;
    for path in &resizes_textures_path {
        if index == 0 {
            index += 1;
            continue;
        }

        let mut delete_textures_path = path.clone();
        delete_textures_path.push("deleted_textures.txt");
        if delete_textures_path.exists() {
            let mut deleted_textures = Vec::new();
            let file = File::open(delete_textures_path.clone()).expect("Error while opening delete_textures.txt");
            let reader = BufReader::new(file);
            for line in reader.lines() {
                let line = line.expect("Error while reading delete_textures.txt");
                deleted_textures.push(line);
            }

            let mut count = 0;

            for deleted_texture in &deleted_textures {
                let mut path_in = resizes_textures_path[0].clone();
                path_in.push(deleted_texture.clone());
                if !path_in.exists() {
                    continue;
                }
                count += 1;
            }

            let mut done = 0;
            blue!("\r{}", done);
            cyan!("/");
            blue!("{}", count);
            cyan!(" textures to recreate in {}x", resizes[index]);
            std::io::stdout().flush().unwrap();

            for deleted_texture in &deleted_textures {
                let mut path_in = resizes_textures_path[0].clone();
                path_in.push(deleted_texture.clone());
                if !path_in.exists() {
                    continue;
                }

                let mut path_out = resizes_textures_path[index].clone();
                path_out.push(deleted_texture);
                upscale_image_pixel_perfect(path_in.to_str().unwrap(), path_out.to_str().unwrap(), resizes[index]);

                done += 1;

                blue!("\r{}", done);
                cyan!("/");
                blue!("{}", count);
                cyan!(" textures to recreate in {}x", resizes[index]);
                std::io::stdout().flush().unwrap();
            }
            green_ln!("\r{} textures recreated in {}x                 ", count, resizes[index]);

            fs::remove_file(delete_textures_path).expect("Error while deleting delete_textures.txt");
        }
        index += 1;
    }
}

fn upscale_image_pixel_perfect(input_path: &str, output_path: &str, upscale: u32) {
    let img = image::open(input_path).expect("Error while opening image");
    let img = img.resize(img.width() * upscale, img.height() * upscale, image::imageops::FilterType::Nearest);
    img.save(output_path).expect("Error while saving image");
}