use std::{fs, str};
use std::io::Write;
use std::time::{Duration, Instant};

use clap::Parser;
use colour::{blue, cyan, cyan_ln, green, green_ln, magenta, magenta_ln, red_ln, yellow, yellow_ln};

use crate::balamod::Balatro;
use crate::luas::*;

mod balamod;
mod luas;

const VERSION: &'static str = "0.1.7a";

#[derive(Parser, Debug, Clone)]
#[clap(version = VERSION)]
struct Args {
    #[clap(short = 'x', long = "inject")]
    inject: bool,
    #[clap(short = 'd', long = "decompile")]
    decompile: bool,
    #[clap(short = 'b', long = "balatro-path")]
    balatro_path: Option<String>,
    #[clap(short = 'c', long = "compress")]
    compress: bool,
    #[clap(short = 'm', long = "modloader")]
    modloader: bool,
    #[clap(short = 'a', long = "auto")]
    auto: bool,
    #[clap(short = 'i', long = "input")]
    input: Option<String>,
    #[clap(short = 'o', long = "output")]
    output: Option<String>,
}

struct StepDuration {
    duration: Duration,
    name: String,
}


fn main() {
    let mut args = Args::parse();

    let mut durations: Vec<StepDuration> = Vec::new();

    if args.inject && args.decompile {
        red_ln!("You can't use -x and -d at the same time!");
        return;
    }

    if args.auto {
        args.compress = true;
        args.input = Some("Balatro.lua".to_string());
        args.output = Some("Balatro.lua".to_string());
    }

    let balatros = balamod::find_balatros();

    let balatro: Balatro;
    if let Some(ref path) = args.balatro_path {
        balatro = Balatro {
            path: std::path::PathBuf::from(path),
            version: "0.0.0".to_string(),
        };
    } else {
        if balatros.len() == 0 {
            red_ln!("No Balatro found!");
            println!("Please specify the path to your Balatro installation with the -bp option");
            return;
        } else if balatros.len() == 1 {
            balatro = balatros[0].clone();
            green!("Balatro ");
            yellow!("v{}", balatro.version);
            green_ln!(" found !")
        } else {
            println!("Multiple Balatro found");
            for (i, balatro) in balatros.iter().enumerate() {
                green!("[");
                yellow!("{}", i + 1);
                green!("] ");
                magenta!("Balatro ");
                cyan!("v{} ", balatro.version);
                magenta!("in ");
                cyan_ln!("{}", balatro.path.display());
            }

            blue!("Please choose a Balatro: ");
            let mut input = String::new();
            std::io::stdin().read_line(&mut input).expect("Error while reading input");
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

    if args.inject {
        inject(args.clone(), balatro.clone(), &mut durations);
    }

    if args.auto {
        if fs::metadata("Balatro.lua").is_ok() {
            yellow_ln!("Deleting existing file...");
            fs::remove_file("Balatro.lua").expect("Error while deleting file");
        }
    }

    if args.decompile || args.auto {
        if fs::metadata("Balatro.lua").is_ok() {
            blue!("Balatro.lua already exists, do you want to replace it? [y/N] ");
            let mut input = String::new();
            std::io::stdin().read_line(&mut input).expect("Error while reading input");
            let input = input.trim();
            if input.eq_ignore_ascii_case("y") || input.eq_ignore_ascii_case("yes") {
                yellow_ln!("Deleting existing file...");
                fs::remove_file("Balatro.lua").expect("Error while deleting file");
            } else {
                yellow_ln!("Leaving...");
                for duration in durations {
                    magenta_ln!("{} took {:?}", duration.name, duration.duration);
                }
                let global_duration = Instant::now().duration_since(global_start);
                magenta_ln!("Total time: {:?}", global_duration);
                return;
            }
        }

        cyan_ln!("Extracting...");
        let exctract_start = Instant::now();
        let bytes = balatro.get_file_data("DAT1.jkr").expect("Error while getting file data");
        durations.push(StepDuration {
            duration: exctract_start.elapsed(),
            name: String::from("Extraction"),
        });
        green_ln!("Done!");

        cyan_ln!("Decompressing...");
        let decompress_start = Instant::now();
        let bytes = balamod::decompress_bytes(bytes.as_slice()).expect("Error while decompressing bytes");
        durations.push(StepDuration {
            duration: decompress_start.elapsed(),
            name: String::from("Decompression"),
        });

        let mut file = fs::File::create("DAT1.luajit").expect("Error while creating file");
        file.write_all(bytes.as_slice()).expect("Error while writing file");
        drop(file);
        // close file to avoid INVALID_HANDLE_VALUE error on windows, i fucking hate windows and myself, i waste too much time on this
        green_ln!("Done!");

        if args.auto {
            cyan_ln!("Extracting...");
            let exctract_start = Instant::now();
            let bytes = balatro.get_file_data("main.lua").expect("Error while getting file data");
            durations.push(StepDuration {
                duration: exctract_start.elapsed(),
                name: String::from("Extraction 2"),
            });
            // write file
            let mut file = fs::File::create("main.lua").expect("Error while creating file");
            file.write_all(bytes.as_slice()).expect("Error while writing file");
            drop(file);
            green_ln!("Done!");
        }


        cyan_ln!("Cleaning up...");
        fs::rename("output/DAT1.lua", "Balatro.lua").expect("Error while renaming file");
        if args.auto {
            if fs::metadata("main.lua").is_ok() {
                fs::remove_file("main.lua").expect("Error while deleting file");
            }
            fs::rename("output/main.lua", "main.lua").expect("Error while renaming file");
        }
        fs::remove_dir_all("output").expect("Error while deleting directory");
        fs::remove_file("DAT1.luajit").expect("Error while deleting file");

        green_ln!("Done!");

        if fs::metadata("deobfmap.json").is_ok() {
            yellow_ln!("Deleting old deobfuscation map...");
            fs::remove_file("deobfmap.json").expect("Error while deleting file");
        }


        if args.modloader || args.auto {
            //inject_modloader(args.clone(), &mut durations);
        }

        if args.auto {
            let mut args_clone = args.clone();
            args_clone.input = Some("Balatro.lua".to_string());
            args_clone.output = Some("DAT1.jkr".to_string());
            inject(args_clone.clone(), balatro.clone(), &mut durations);
            args_clone.input = Some("main.lua".to_string());
            args_clone.output = Some("main.lua".to_string());
            args_clone.compress = false;
            inject(args_clone, balatro.clone(), &mut durations);
        }

        if args.auto {
            yellow_ln!("Deleting injected file...");
            if fs::metadata("Balatro.lua").is_ok() {
                fs::remove_file("Balatro.lua").expect("Error while deleting file");
            }
            if fs::metadata("main.lua").is_ok() {
                fs::remove_file("main.lua").expect("Error while deleting file");
            }
            green_ln!("Done!");
        }

        for duration in durations {
            magenta_ln!("{} took {:?}", duration.name, duration.duration);
        }

        let global_duration = Instant::now().duration_since(global_start);
        magenta_ln!("Total time: {:?}", global_duration);
    }
}

fn inject_modloader(main_lua: String, uidef_lua: String, balatro: Balatro, durations: &mut Vec<StepDuration>) -> (String, String) {
    let mut new_main = main_lua.clone();
    let mut new_uidef = uidef_lua.clone();

    cyan_ln!("Implementing modloader on main...");
    let start = Instant::now();

    // check if the string start with "-- balamod"
    if new_main.starts_with("-- balamod") {
        red_ln!("The main already has the modloader, skipping...");
    } else {
        let mod_core = balatro.build_mod_core().unwrap();
        new_main = format!("-- balamod\n{}\n\n{}\n", mod_core, new_main);
    }

    new_main = new_main.replace(
        "function love.update( dt )",
        format!("function love.update( dt )\n{}", get_pre_update_event()).as_str()
    );

    new_main = new_main.replace(
        "G:update(dt)",
        format!("G:update(dt)\n{}", get_post_update_event()).as_str()
    );

    new_main = new_main.replace(
        "function love.draw()",
        format!("function love.draw()\n{}", get_pre_render_event()).as_str()
    );

    new_main = new_main.replace(
        "G:draw()",
        format!("G:draw()\n{}", get_post_render_event()).as_str()
    );

    new_main = new_main.replace(
        "function love.keypressed(key)",
        format!("function love.keypressed(key)\n{}", get_key_pressed_event()).as_str()
    );


    durations.push(StepDuration {
        duration: start.elapsed(),
        name: String::from("Modloader implementation (main)"),
    });


    cyan_ln!("Implementing modloader on uidef...");
    let start = Instant::now();

    new_uidef = new_uidef.replace(
        "\"show_credits\", minw = 5}",
        "\"show_credits\", minw = 5}\n        mods_btn = UIBox_button{ label = {\"Mods\"}, button = \"show_mods\", minw = 5}"
    );

    new_uidef = new_uidef.replace(
        "        your_collection,\n        credits",
        "        your_collection,\n        credits,\n        mods_btn",
    );

    new_uidef = new_uidef.replace(
        "    local credits = nil",
        "    local credits = nil\n    local mods_btn = nil",
    );

    let modloader = get_mod_loader().to_string().replace("{balamod_version}", VERSION);

    new_uidef.push_str(modloader.as_str());

    durations.push(StepDuration {
        duration: start.elapsed(),
        name: String::from("Modloader implementation (uidef)"),
    });

    green_ln!("Done!");

    (new_main, new_uidef)
}

#[cfg(test)]
mod tests {
    use super::*;

    #[test]
    fn test_injector() {
        let main_lua = fs::read_to_string("main.lua").expect("Error while reading file");
        let uidef_lua = fs::read_to_string("functions/UI_definitions.lua").expect("Error while reading file");

        let balatros = balamod::find_balatros();
        let balatro = &balatros[0];
        let mut timings = Vec::new();
        let (new_main, new_uidef) = inject_modloader(main_lua, uidef_lua, balatro.clone(), &mut timings);
        // print timings
        for timing in timings {
            println!("{} took {:?}", timing.name, timing.duration);
        }

        // save to main_modded.lua and game_modded.lua
        fs::write("main_modded.lua", new_main).expect("Error while writing file");
        fs::write("functions/UI_definitions_modded.lua", new_uidef).expect("Error while writing file");
    }
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
