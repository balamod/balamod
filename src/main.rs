use std::fs::File;
use std::io::Write;
use std::path::PathBuf;
use std::time::{Duration, Instant};
use std::{fs, str};

use clap::Parser;
use colour::{
    blue, cyan, cyan_ln, green, green_ln, magenta, magenta_ln, red_ln, yellow, yellow_ln,
};

use crate::balamod::Balatro;
use crate::luas::*;

mod balamod;
mod dependencies;
mod luas;
mod finder;

const VERSION: &'static str = "0.1.11";

#[derive(Parser, Debug, Clone)]
#[clap(version = VERSION)]
struct Args {
    #[clap(short = 'x', long = "inject")]
    inject: bool,
    #[clap(short = 'b', long = "balatro-path")]
    balatro_path: Option<String>,
    #[clap(short = 'c', long = "compress")]
    compress: bool,
    #[clap(short = 'a', long = "auto")]
    auto: bool,
    #[clap(short = 'd', long = "decompile")]
    decompile: bool,
    #[clap(short = 'i', long = "input")]
    input: Option<String>,
    #[clap(short = 'o', long = "output")]
    output: Option<String>,
    #[clap(short = 'u', long = "uninstall")]
    uninstall: bool,
}

struct StepDuration {
    duration: Duration,
    name: String,
}

fn main() {
    let args = Args::parse();

    let mut durations: Vec<StepDuration> = Vec::new();

    if args.inject && args.auto {
        red_ln!("You can't use -x and -a at the same time!");
        return;
    }

    if args.inject && args.decompile {
        red_ln!("You can't use -x and -d at the same time!");
        return;
    }

    if args.auto && args.decompile {
        red_ln!("You can't use -a and -d at the same time!");
        return;
    }

    let balatros = balamod::find_balatros();

    let balatro: Balatro;
    if let Some(ref path) = args.balatro_path {
        balatro = Balatro {
            path: std::path::PathBuf::from(path),
        };
    } else {
        if balatros.len() == 0 {
            red_ln!("No Balatro found!");
            println!("Please specify the path to your Balatro installation with the -b option");
            return;
        } else if balatros.len() == 1 {
            balatro = balatros[0].clone();
            green!("Balatro ");
            yellow!("v{}", balatro.get_version().unwrap());
            green_ln!(" found !")
        } else {
            println!("Multiple Balatro found");
            for (i, balatro) in balatros.iter().enumerate() {
                green!("[");
                yellow!("{}", i + 1);
                green!("] ");
                magenta!("Balatro ");
                cyan!("v{} ", balatro.get_version().unwrap());
                magenta!("in ");
                cyan_ln!("{}", balatro.path.display());
            }

            blue!("Please choose a Balatro: ");
            let mut input = String::new();
            std::io::stdin()
                .read_line(&mut input)
                .expect("Error while reading input");
            let input = input.trim();
            let input: usize = match input.parse() {
                Ok(input) => input,
                Err(_) => {
                    red_ln!("Invalid input!");
                    return;
                }
            };
            if input > balatros.len() || input == 0 {
                red_ln!("Invalid input!");
                return;
            }
            balatro = balatros[input - 1].clone();
        }
    }

    let global_start = Instant::now();

    if args.uninstall {
        uninstall(balatro.clone(), &mut durations);
        return;
    }

    if args.inject {
        inject(args.clone(), balatro.clone(), &mut durations);
    }

    if args.decompile {
        decompile_game(balatro.clone(), args.output, &mut durations);
    }

    if args.auto {
        // check for macos intel
        if cfg!(all(
            target_os = "macos",
            not(any(target_arch = "aarch64", target_arch = "arm"))
        )) {
            red_ln!("Architecture is not supported, skipping modloader injection...");
        } else {
            install(balatro, &mut durations);
        }
    }

    magenta_ln!("Total time: {:?}", global_start.elapsed());
    for duration in durations {
        magenta_ln!("{}: {:?}", duration.name, duration.duration);
    }
}

#[cfg(all(
    target_os = "macos",
    not(any(target_arch = "aarch64", target_arch = "arm"))
))]
fn inject_modloader(
    main_lua: String,
    uidef_lua: String,
    // balatro: Balatro,
    durations: &mut Vec<StepDuration>,
) -> (String, String) {
    red_ln!("Architecture is not supported, skipping modloader injection...");
    return (main_lua, uidef_lua);
}

#[cfg(not(all(
    target_os = "macos",
    not(any(target_arch = "aarch64", target_arch = "arm"))
)))]
fn inject_modloader(
    main_lua: String,
    uidef_lua: String,
    // balatro: Balatro,
    durations: &mut Vec<StepDuration>,
) -> (String, String) {
    let mut new_main = main_lua.clone();
    let mut new_uidef = uidef_lua.clone();

    cyan_ln!("Implementing modloader on main...");
    let start = Instant::now();

    if new_main.starts_with("-- balamod") {
        yellow_ln!("The main already has the modloader, skipping...");
    } else {
        new_main = format!("-- balamod\n{}\n\n{}\n", get_imports(),new_main);

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
            "function love.keyreleased(key)",
            format!(
                "function love.keyreleased(key)\n{}",
                get_key_released_event()
            )
            .as_str(),
        );

        new_main = new_main.replace(
            "function love.mousereleased(x, y, button)",
            format!(
                "function love.mousereleased(x, y, button)\n{}",
                get_mouse_released_event()
            )
            .as_str(),
        );

        new_main = new_main.replace(
            "function love.mousepressed(x, y, button, touch)",
            format!(
                "function love.mousepressed(x, y, button, touch)\n{}",
                get_mouse_pressed_event()
            )
            .as_str(),
        );

        new_main = new_main.replace(
            "function love.errhand(msg)",
            format!(
                "function love.errhand(msg)\n{}",
                get_error_handler()
            ).as_str(),
        );

        new_main = new_main.replace(
            "function love.load()",
            format!(
                "function love.load(args)\n{}",
                get_load_handler()
            ).as_str(),
        );

        new_main = new_main.replace(
            "function love.quit()",
            format!(
                "function love.quit()\n{}",
                get_quit_handler()
            ).as_str(),
        );

        new_main.push_str(
            get_mousewheel_event()
        );

        let modloader = get_mod_loader()
            .to_string()
            .replace("{balamod_version}", VERSION);

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
            "{n=G.UIT.O, config={object = twitter}},",
            r#"{n=G.UIT.O, config={object = twitter}},
        }}
    }} or nil,
    {n=G.UIT.R, config = {align = "cm", padding = 0.2, r = 0.1, emboss = 0.1, colour = G.C.L_BLACK}, nodes={
      {n=G.UIT.R, config={align = "cm", padding = 0.15, minw = 1, r = 0.1, hover = true, colour = G.C.PURPLE, button = 'show_mods', shadow = true}, nodes={
        {n=G.UIT.T, config={text = "MODS", scale = 0.6, colour = G.C.UI.TEXT_LIGHT, shadow = true}}"#,
        );

        durations.push(StepDuration {
            duration: start.elapsed(),
            name: String::from("Modloader implementation (uidef)"),
        });
    }

    green_ln!("Done!");

    (new_main, new_uidef)
}

fn uninstall(balatro: Balatro, durations: &mut Vec<StepDuration>) {
    // restore from the backup
    let start = Instant::now();
    let backup_path = balatro.get_exe_path().clone().with_extension("bak");
    if fs::metadata(backup_path.as_path()).is_ok() {
        yellow_ln!("Restoring backup...");
        fs::remove_file(balatro.get_exe_path()).expect("Error while deleting file");
        fs::copy(backup_path.as_path(), balatro.get_exe_path())
            .expect("Error while copying file");
        fs::remove_file(backup_path.as_path()).expect("Error while deleting file");
        green_ln!("Done!");
    } else {
        red_ln!("No backup found!");
    }
    durations.push(StepDuration {
        duration: start.elapsed(),
        name: String::from("Restoration of executable"),
    });
    cyan_ln!("Uninstalling dependencies...");
    let start = Instant::now();
    balatro
        .remove_dependencies()
        .expect("Error while uninstalling dependencies");
    durations.push(StepDuration {
        duration: start.elapsed(),
        name: String::from("Dependency uninstallation"),
    });
}

fn install(balatro: Balatro, durations: &mut Vec<StepDuration>) {
    let start = Instant::now();
    // Copy the balatro executable to back it up and restore it later if needed
    let backup_path = balatro.get_exe_path().clone().with_extension("bak");
    if fs::metadata(backup_path.as_path()).is_ok() {
        yellow_ln!("Deleting existing backup...");
        fs::remove_file(backup_path.as_path()).expect("Error while deleting file");
    }
    fs::copy(balatro.get_exe_path(), backup_path.as_path()).expect("Error while copying file");
    durations.push(StepDuration {
        duration: start.elapsed(),
        name: String::from("Backup of executable"),
    });

    let main_lua = balatro
        .get_file_as_string("main.lua", false)
        .expect("Error while reading file");
    let uidef_lua = balatro
        .get_file_as_string("functions/UI_definitions.lua", false)
        .expect("Error while reading file");

    let (new_main, new_uidef) = inject_modloader(main_lua, uidef_lua, durations);

    cyan_ln!("Injecting main");
    let start: Instant = Instant::now();
    balatro
        .replace_file("main.lua", new_main.as_bytes())
        .expect("Error while replacing file");
    durations.push(StepDuration {
        duration: start.elapsed(),
        name: String::from("Modloader injection (main)"),
    });
    green_ln!("Done!");

    cyan_ln!("Injecting uidef");
    let start = Instant::now();
    balatro
        .replace_file("functions/UI_definitions.lua", new_uidef.as_bytes())
        .expect("Error while replacing file");
    durations.push(StepDuration {
        duration: start.elapsed(),
        name: String::from("Modloader injection (uidef)"),
    });
    cyan_ln!("Injecting dependencies");
    let start = Instant::now();
    balatro
        .inject_dependencies()
        .expect("Error while injecting dependencies");
    durations.push(StepDuration {
        duration: start.elapsed(),
        name: String::from("Dependency injection"),
    });
    green_ln!("Done!");
}

fn inject(mut args: Args, balatro: Balatro, durations: &mut Vec<StepDuration>) {
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
            compression_output = args
                .output
                .clone()
                .unwrap()
                .split(".lua")
                .collect::<String>();
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
        balatro.compress_file(
            args.input.clone().unwrap().as_str(),
            compression_output.as_str(),
        )
        .expect("Error while compressing file");

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

    let input_bytes =
        fs::read(args.input.clone().unwrap()).expect("Error while reading input file");
    let input_bytes = input_bytes.as_slice();

    cyan_ln!("Injecting...");
    let inject_start = Instant::now();

    balatro
        .replace_file(args.output.clone().unwrap().as_str(), input_bytes)
        .expect("Error while replacing file");

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

fn decompile_game(
    balatro: Balatro,
    output_folder: Option<String>,
    durations: &mut Vec<StepDuration>,
) {
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
        let file_bytes = balatro
            .get_file_data(path.as_str())
            .expect("Error while reading file");

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
                file.write_all(&file_bytes)
                    .expect("Error while writing to file");
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
