use std::{fs, str};
use std::fs::File;
use std::io::Write;
use std::path::PathBuf;
use std::time::{Duration, Instant};

use clap::Parser;
use colour::{blue, cyan, cyan_ln, green, green_ln, magenta, magenta_ln, red_ln, yellow, yellow_ln};

use crate::balamod::Balatro;
use crate::luas::*;

mod balamod;
mod luas;

const VERSION: &'static str = "0.1.9a";

#[cfg(all(target_os = "macos", not(any(target_arch = "aarch64", target_arch = "arm"))))]
pub fn inject_modloader(main_lua: String, uidef_lua: String, balatro: Balatro, durations: &mut Vec<StepDuration>) -> (String, String) {
    red_ln!("Architecture is not supported, skipping modloader injection...");
    return (main_lua, uidef_lua);
}

#[cfg(not(all(target_os = "macos", not(any(target_arch = "aarch64", target_arch = "arm")))))]
pub fn inject_modloader(main_lua: String, uidef_lua: String, balatro: Balatro, durations: &mut Vec<StepDuration>) -> (String, String) {
    let mut new_main = main_lua.clone();
    let mut new_uidef = uidef_lua.clone();

    cyan_ln!("Implementing modloader on main...");
    let start = Instant::now();

    if new_main.starts_with("-- balamod") {
        yellow_ln!("The main already has the modloader, skipping...");
    } else {
        let mod_core = balatro.build_mod_core().unwrap();
        new_main = format!("-- balamod\n{}\n\n{}\n", mod_core, new_main);


        new_main = new_main.replace(
            "function love.update( dt )",
            format!("function love.update( dt )\n{}", get_pre_update_event()).as_str(),
        );

        new_main = new_main.replace(
            "G:update(dt)",
            format!("G:update(dt)\n{}", get_post_update_event()).as_str(),
        );

        new_main = new_main.replace(
            "function love.draw()",
            format!("function love.draw()\n{}", get_pre_render_event()).as_str(),
        );

        new_main = new_main.replace(
            "G:draw()",
            format!("G:draw()\n{}", get_post_render_event()).as_str(),
        );

        new_main = new_main.replace(
            "function love.keypressed(key)",
            format!("function love.keypressed(key)\n{}", get_key_pressed_event()).as_str(),
        );

        new_main = new_main.replace(
            "function love.mousepressed(x, y, button, touch)",
            format!("function love.mousepressed(x, y, button, touch)\n{}", get_mouse_pressed_event()).as_str()
        );

        let modloader = get_mod_loader().to_string().replace("{balamod_version}", VERSION);

        new_main.push_str(modloader.as_str());
    }


    durations.push(StepDuration {
        duration: start.elapsed(),
        name: String::from("Modloader implementation (main)"),
    });


    cyan_ln!("Implementing modloader on uidef...");
    let start = Instant::now();

    if new_uidef.starts_with("-- balamod") {
        yellow_ln!("The uidef already has the modloader, skipping...");
    } else {
        new_uidef = format!("-- balamod\n\n{}", new_uidef);

        new_uidef = new_uidef.replace(
            "\"show_credits\", minw = 5}",
            "\"show_credits\", minw = 5}\n        mods_btn = UIBox_button{ label = {\"Mods\"}, button = \"show_mods\", minw = 5}",
        );

        new_uidef = new_uidef.replace(
            "      your_collection,\n      credits",
            "      your_collection,\n      credits,\n      mods_btn",
        );

        new_uidef = new_uidef.replace(
            "  local credits = nil",
            "  local credits = nil\n  local mods_btn = nil",
        );

        durations.push(StepDuration {
            duration: start.elapsed(),
            name: String::from("Modloader implementation (uidef)"),
        });
    }

    green_ln!("Done!");

    (new_main, new_uidef)
}

pub fn inject(mut args: Args, balatro: Balatro, durations: &mut Vec<StepDuration>) {
    if args.input.clone().is_none() {
        args.input = Some("Balatro.lua".to_string());
    }

    if args.output.clone().is_none() {
        args.output = Some("DAT1.jkr".to_string());
    }

    let mut need_cleanup = false;
    if args.compress {
        let mut compression_output: String;
        if args.output.clone().unwrap().ends_with(".lua") {
            compression_output = args.output.clone().unwrap().split(".lua").collect::<String>();
        } else {
            compression_output = args.output.clone().unwrap().clone();
        }
        if !compression_output.ends_with(".jkr") {
            compression_output.push_str(".jkr");
        }

        if fs::metadata(compression_output.as_str()).is_ok() {
            yellow_ln!("Deleting existing file...");
            fs::remove_file(compression_output.as_str()).expect("Error while deleting file");
        }

        cyan_ln!("Compressing {} ...", args.input.clone().unwrap());
        let compress_start: Instant = Instant::now();
        balamod::compress_file(args.input.clone().unwrap().as_str(), compression_output.as_str()).expect("Error while compressing file");

        durations.push(StepDuration {
            duration: compress_start.elapsed(),
            name: String::from("Compression"),
        });
        if !compression_output.eq_ignore_ascii_case(args.input.as_ref().unwrap()) {
            need_cleanup = true;
            args.input = Some(compression_output);
        }
        green_ln!("Done!");
    }

    let input_bytes = fs::read(args.input.clone().unwrap()).expect("Error while reading input file");
    let input_bytes = input_bytes.as_slice();

    cyan_ln!("Injecting...");
    let inject_start = Instant::now();

    balatro.replace_file(args.output.clone().unwrap().as_str(), input_bytes).expect("Error while replacing file");

    durations.push(StepDuration {
        duration: inject_start.elapsed(),
        name: String::from("Injection"),
    });
    green_ln!("Done!");

    if need_cleanup {
        yellow_ln!("Cleaning up...");
        fs::remove_file(args.input.clone().unwrap()).expect("Error while deleting file");
        green_ln!("Done!");
    }
}

pub fn decompile_game(balatro: Balatro, output_folder: Option<String>, durations: &mut Vec<StepDuration>) {
    let mut output_folder = output_folder.unwrap_or_else(|| "decompiled".to_string());

    if !output_folder.ends_with("/") {
        output_folder.push_str("/");
    }

    if fs::metadata(output_folder.as_str()).is_ok() {
        yellow_ln!("Deleting existing folder...");
        fs::remove_dir_all(output_folder.as_str()).expect("Error while deleting folder");
    }

    cyan_ln!("Decompiling...");
    let decompile_start = Instant::now();
    let paths = balatro.get_all_files().unwrap();
    for path in paths {
        if path.ends_with("/") {
            continue;
        }
        let file_bytes = balatro.get_file_data(path.as_str()).expect("Error while reading file");

        let normalized_path = path.replace("\\", "/");
        let mut full_path = PathBuf::from(&output_folder);
        full_path.push(normalized_path);

        if let Some(parent_dirs) = full_path.parent() {
            if !parent_dirs.exists() {
                fs::create_dir_all(parent_dirs).expect("Error while creating directories");
            }
        }

        if full_path.as_path().is_dir() {
            continue;
        }

        match File::create(&full_path) {
            Ok(mut file) => {
                file.write_all(&file_bytes).expect("Error while writing to file");
            }
            Err(e) => {
                println!("Error while creating file: {:?}", e);
                println!("Failed path: {:?}", full_path);
                break;
            }
        }
    }

    green_ln!("Done!");
    durations.push(StepDuration {
        duration: decompile_start.elapsed(),
        name: String::from("Decompilation"),
    });
}