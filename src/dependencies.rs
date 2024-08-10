fn get_tar_file_name(linux_native: bool) -> String {
    let mut tar_file = String::new();

    if cfg!(target_os = "macos") {
        tar_file = String::from("balamod-macos");
    } else if cfg!(target_os = "windows") {
        tar_file = String::from("balamod-windows");
    } else if cfg!(target_os = "linux") {
        //tar_file = String::from("balamod-linux-proton");
        if linux_native {
            tar_file = String::from("balamod-linux-native");
        } else {
            tar_file = String::from("balamod-linux-proton");
        }
    }

    if tar_file.is_empty() {
        panic!("Unsupported OS");
    }

    format!("{}.tar.gz", tar_file)
}

pub fn download_tar(tag: Option<String>, linux_native: bool) -> Result<Vec<u8>, Box<dyn std::error::Error>> {
    let url = match tag {
        Some(tag) => format!("https://github.com/balamod/balamod_lua/releases/download/{}/{}", tag, get_tar_file_name(linux_native)),
        None => format!("https://github.com/balamod/balamod_lua/releases/latest/download/{}", get_tar_file_name(linux_native))
    };
    let response = reqwest::blocking::get(&url)?;
    let body = response.bytes()?;
    Ok(body.to_vec())
}

pub fn unpack_tar(dir: &str, tar: Vec<u8>, linux_native: bool) -> Result<(), Box<dyn std::error::Error>> {
    let tar = std::io::Cursor::new(tar);
    let mut archive = tar::Archive::new(flate2::read::GzDecoder::new(tar));
    archive.unpack(dir)?;
    let tar_file_name = get_tar_file_name(linux_native);
    // regt before first .
    let dir_name = tar_file_name.split('.').next().unwrap();
    // rename dir to balamod
    std::fs::rename(format!("{}/{}", dir, dir_name), format!("{}/balamod", dir))?; // rename dir to balamod
    Ok(())
}

pub fn download_patched_main() -> Result<Vec<u8>, Box<dyn std::error::Error>> {
    let timestamp = std::time::SystemTime::now().duration_since(std::time::UNIX_EPOCH).unwrap().as_secs();
    let url = format!("https://raw.githubusercontent.com/balamod/balamod_lua/main/main.patch.lua?t={}", timestamp); // cache buster
    let response = reqwest::blocking::get(&url)?;
    let body = response.bytes()?;
    Ok(body.to_vec())
}