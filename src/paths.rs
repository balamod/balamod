use textfmt::*;
use std::path::{Path, PathBuf};

#[cfg(target_os = "macos")]
const STEAM_LOCATION: [&'static str; 3] = ["Library", "Application Support", "Steam"];
#[cfg(target_os = "linux")]
const STEAM_LOCATION: [&'static str; 3] = [".local", "share", "Steam"];

#[cfg(target_os = "windows")]
pub fn get_balatro_paths() -> Vec<PathBuf> {
    let path = winreg::RegKey::predef(winreg::enums::HKEY_LOCAL_MACHINE)
        .open_subkey("SOFTWARE\\WOW6432Node\\Valve\\Steam")
        .map(|k| k.get_value("InstallPath"))
        .flatten()
        .map(|str: String| PathBuf::from(&str))
        .unwrap_or_else(|_| {
            "Could not read steam install path from Registry! Trying standard installation path in `Program Files (x86)`"
                .red()
                .italic()
                .println();
            return std::env::var("ProgramFiles(x86)")
                .map(|str| 
                    PathBuf::from(&str)
                        .join("Steam"))
                .unwrap_or(PathBuf::new());
        });
    if path.exists() {
        return get_library_folders(&path);
    } else {
        "Could not find Steam folder!"
            .red()
            .underline()
            .bold()
            .println();
        return Vec::new();
    }
}

#[cfg(any(target_os = "linux", target_os = "macos"))]
pub fn get_balatro_paths() -> Vec<PathBuf> {
    std::env::var("HOME")
        .map(|str| PathBuf::from(str))
        .map(|mut path| {
            path.extend(STEAM_LOCATION); 
            return get_library_folders(&path);
        })
        .unwrap_or_else(|_| {
            "Impossible to get your home dir!"
                .red()
                .underline()
                .bold()
                .println();
            return Vec::new();
        })
}

fn get_library_folders(steam_path: &Path) -> Vec<PathBuf> {
    std::fs::read_to_string(steam_path.join("steamapps").join("libraryfolders.vdf"))
        .expect("Failed to read libraryfolders.vdf")
        .lines()
        .filter(|line| line.contains("\t\t\"path\"\t\t"))
        .filter_map(|line| 
            line.split("\"")
                .skip(3)
                .next()
                .map(|path| Path::new(path)))
        .map(|path| 
            PathBuf::from(path)
                .join("steamapps")
                .join("common")
                .join("Balatro"))
        .filter(|path| path.exists())
        .collect()
}

#[cfg(target_os = "macos")]
pub fn get_save_dir(_linux_native: bool) -> PathBuf { 
    PathBuf::from("Users")
        .join(std::env::var("USER").unwrap())
        .join("Library")
        .join("Application Support")
        .join("Balatro")
}

#[cfg(target_os = "windows")]
pub fn get_save_dir(_linux_native: bool) -> PathBuf { 
    PathBuf::from(std::env::var("APPDATA").unwrap())
        .join("Balatro")
}

#[cfg(target_os = "linux")]
pub fn get_save_dir(linux_native: bool) -> PathBuf { 
    if linux_native {
        PathBuf::from(std::env::var("HOME").unwrap())
            .join(".local") 
            .join("share") 
            .join("love") 
            .join("Balatro")
    } else {
        PathBuf::from(std::env::var("HOME").unwrap())
            .join(".local") 
            .join("share") 
            .join("Steam")
            .join("steamapps")
            .join("compatdata")
            .join("2379780")
            .join("pfx")
            .join("drive_c")
            .join("users")
            .join("steamuser")
            .join("AppData")
            .join("Roaming")
            .join("Balatro")
    }
}

#[cfg(target_os = "macos")]
pub fn get_exe_path(path: &Path) -> PathBuf { 
    let mut path = path.join("Balatro.app");
    path.push("Contents");
    path.push("Resources");
    path.push("Balatro.love");
    return path;
}

#[cfg(any(target_os = "windows", target_os = "linux"))]
pub fn get_exe_path(path: &Path) -> PathBuf { path.join("Balatro.exe") }
