use async_compat::CompatExt;
use textfmt::*;
use crate::Error;

#[cfg(target_os = "macos")]
const TAR_FILE: &'static str = "balamod-macos.tar.gz";
#[cfg(target_os = "windows")]
const TAR_FILE: &'static str = "balamod-windows.tar.gz";
#[cfg(target_os = "linux")]
const TAR_FILE: &'static str = "balamod-linux-native.tar.gz";
#[cfg(target_os = "linux")]
const TAR_FILE_PROTON: &'static str = "balamod-linux-proton.tar.gz";
#[cfg(target_os = "macos")]
const LIB_FILE: &'static str = "balalib.dylib";
#[cfg(target_os = "windows")]
const LIB_FILE: &'static str = "balalib.dll";
#[cfg(target_os = "linux")]
const LIB_FILE: &'static str = "balalib.so";
const LIB_FILE_PROTON: &'static str = "balalib.dll";
const BALAMOD_LUA_RELEASES: &'static str = "https://github.com/balamod/balamod_lua/releases/download/";
const BALAMOD_LUA_LATEST: &'static str = "https://github.com/balamod/balamod_lua/releases/latest/download/";
const BALALIB_RELEASES: &'static str = "https://github.com/balamod/balalib/releases/download/";
const BALALIB_LATEST: &'static str = "https://github.com/balamod/balalib/releases/latest/download/";
pub const MAIN_PATCH: &'static str = "https://raw.githubusercontent.com/balamod/balamod_lua/main/main.patch.lua";

#[cfg(target_os = "linux")]
pub fn get_tar_file_name(linux_native: bool) -> &'static str { if linux_native { TAR_FILE } else { TAR_FILE_PROTON } }
#[cfg(any(target_os = "macos", target_os = "windows"))]
pub fn get_tar_file_name(_linux_native: bool) -> &'static str { TAR_FILE }
#[cfg(not(any(target_os = "macos", target_os = "windows", target_os = "linux")))]
pub fn get_tar_file_name(_linux_native: bool) -> &'static str { panic!("Unsupported OS") }

pub async fn finish_download
    <T: Future<Output = Result<reqwest::Response, reqwest::Error>>>
    (ft: T) 
    -> Result<Vec<u8>, Error> { Ok(ft.await?.bytes().await?.to_vec()) }

pub fn get_tar_url(tag: Option<&str>, linux_native: bool) -> String {
    match tag {
        Some(tag) => BALAMOD_LUA_RELEASES.to_string() + tag + "/" + get_tar_file_name(linux_native),
        None => BALAMOD_LUA_LATEST.to_string() + get_tar_file_name(linux_native),
    }
}

#[cfg(not(any(target_os = "macos", target_os = "windows", target_os = "linux")))]
pub fn get_balalib_name(linux_native: bool) -> &'static str { panic!("Unsupported OS") }
#[cfg(target_os = "linux")]
pub fn get_balalib_name(linux_native: bool) -> &'static str {
    if linux_native { LIB_FILE } else { LIB_FILE_PROTON }
}
#[cfg(any(target_os = "macos", target_os = "windows"))]
pub fn get_balalib_name(linux_native: bool) -> &'static str { LIB_FILE }

pub fn get_balalib_url(tag: Option<&str>, linux_native: bool) -> String {
    match tag {
        Some(tag) => BALALIB_RELEASES.to_string() + tag + "/" + get_tar_file_name(linux_native),
        None => BALALIB_LATEST.to_string() + get_tar_file_name(linux_native),
    }
}

pub fn download_file(url: &str) 
    -> async_compat::Compat<impl Future<Output = Result<reqwest::Response, reqwest::Error>>>  
{ reqwest::get(url).compat() }

pub async fn balamod_version_exists(ver: &str, linux_native: bool) -> bool {
    reqwest::get(&(BALAMOD_LUA_RELEASES.to_string() + ver + get_tar_file_name(linux_native)))
        .compat()
        .await
        .unwrap()
        .status()
        .as_u16() != 404
}

pub fn get_balatro_path<'a>(
    balatro_path: Option<&'a str>, 
    balatros: &'a Vec<std::path::PathBuf>,
) 
    -> Result<&'a std::path::Path, Error> 
{
    match balatro_path {
        Some(path) => Ok(std::path::Path::new(path)),
        None => {
            if balatros.len() == 0 {
                Err(no_balatro_found())
            } else if balatros.len() == 1 {
                one_balatro_found(&balatros)
            } else {
                multiple_balatros_found(&balatros)
            }
        },
    }
}

fn no_balatro_found() -> Error {
    "No Balatro found!"
        .bright_red()
        .underline()
        .eprintln();
    "Please specify the path to your Balatro installation with the -b option"
        .bright_white()
        .eprintln();
    "Balatro not found".into()
}

fn one_balatro_found<'a>(balatros: &'a Vec<std::path::PathBuf>) 
    -> Result<&'a std::path::Path, Error> 
{
    "Balatro "
        .green()
        .print();
    ("v".to_string() + &crate::archive::zip_utils::get_version(&balatros[0])?)
        .yellow()
        .print();
    " found!"
        .green()
        .println();
    Ok(balatros[0].as_path())
}

fn multiple_balatros_found<'a>(balatros: &'a Vec<std::path::PathBuf>)
    -> Result<&'a std::path::Path, Error>
{
    println!("Multiple Balatro found");
    for (i, balatro_path) in balatros.iter().enumerate() {
        "[".green().print();
        (i + 1).to_string().yellow().print();
        "] ".green().print();
        "Balatro ".magenta().print();
        ("v".to_string() + &crate::archive::zip_utils::get_version(balatro_path).unwrap()).cyan().italic().print();
        "in ".magenta().print();
        balatro_path.display().to_string().cyan().italic().println();
    }

    "Please choose a Balatro version: ".blue().print();
    let mut buf = String::new();
    std::io::stdin().read_line(&mut buf)?;
    let input: usize = buf.trim().parse()?;
    if input > balatros.len() || input == 0 {
        "Invalid input!".bg_red().bright_white().underline().eprintln();
        return Err("Invalid input".into());
    }
    Ok(balatros[input - 1].as_path())

}
