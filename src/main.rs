use std::{fs, str};
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
    #[clap(short = 'b', long = "balatro-path")]
    balatro_path: Option<String>,
    #[clap(short = 'c', long = "compress")]
    compress: bool,
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
    let args = Args::parse();

    let mut durations: Vec<StepDuration> = Vec::new();

    if args.inject && args.auto {
        red_ln!("You can't use -x and -a at the same time!");
        return;
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
        let main_lua = balatro.get_file_as_string("main.lua", false).expect("Error while reading file");
        let uidef_lua = balatro.get_file_as_string("functions/UI_definitions.lua", false).expect("Error while reading file");

        let (new_main, new_uidef) = inject_modloader(main_lua, uidef_lua, balatro.clone(), &mut durations);

        cyan_ln!("Injecting main");
        let start = Instant::now();
        balatro.replace_file("main.lua", new_main.as_bytes()).expect("Error while replacing file");
        durations.push(StepDuration {
            duration: start.elapsed(),
            name: String::from("Modloader injection (main)"),
        });
        green_ln!("Done!");

        cyan_ln!("Injecting uidef");
        let start = Instant::now();
        balatro.replace_file("functions/UI_definitions.lua", new_uidef.as_bytes()).expect("Error while replacing file");
        durations.push(StepDuration {
            duration: start.elapsed(),
            name: String::from("Modloader injection (uidef)"),
        });
        green_ln!("Done!");
    }

    magenta_ln!("Total time: {:?}", global_start.elapsed());
    for duration in durations {
        magenta_ln!("{}: {:?}", duration.name, duration.duration);
    }
}

fn inject_modloader(main_lua: String, uidef_lua: String, balatro: Balatro, durations: &mut Vec<StepDuration>) -> (String, String) {
    let mut new_main = main_lua.clone();
    let mut new_uidef = uidef_lua.clone();

    cyan_ln!("Implementing modloader on main...");
    let start = Instant::now();

    // check if the string start with "-- balamod"
    if new_main.starts_with("-- balamod") {
        yellow_ln!("The main already has the modloader, skipping...");
    } else {
        let mod_core = balatro.build_mod_core().unwrap();
        new_main = format!("-- balamod\n{}\n\n{}\n", mod_core, new_main);


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
    }

    green_ln!("Done!");

    (new_main, new_uidef)
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
