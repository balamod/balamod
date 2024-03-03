use std::{fs, str};
use std::fs::File;
use std::io::Write;
use std::path::PathBuf;
use std::time::{Duration, Instant};

use clap::Parser;
use colour::{blue, cyan, cyan_ln, green, green_ln, magenta, magenta_ln, red_ln, yellow, yellow_ln};

use crate::balamod::Balatro;
use crate::balamod::injector;
use crate::luas::*;

mod balamod;
mod luas;

const VERSION: &'static str = "0.1.9a";

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
}

struct StepDuration {
    duration: Duration,
    name: String,
}


pub fn main_cli() {
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
            version: "0.0.0".to_string(),
        };
    } else {
        if balatros.len() == 0 {
            red_ln!("No Balatro found!");
            println!("Please specify the path to your Balatro installation with the -b option");
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

    if args.decompile {
        decompile_game(balatro.clone(), args.output, &mut durations);
    }

    if args.auto {
        // check for macos intel
        if cfg!(all(target_os = "macos", not(any(target_arch = "aarch64", target_arch = "arm")))) {
            red_ln!("Architecture is not supported, skipping modloader injection...");
        } else {
            let main_lua = balatro.get_file_as_string("main.lua", false).expect("Error while reading file");
            let uidef_lua = balatro.get_file_as_string("functions/UI_definitions.lua", false).expect("Error while reading file");

            let (new_main, new_uidef) = inject_modloader(main_lua, uidef_lua, balatro.clone(), &mut durations);

            cyan_ln!("Injecting main");
            let start: Instant = Instant::now();
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
    }

    magenta_ln!("Total time: {:?}", global_start.elapsed());
    for duration in durations {
        magenta_ln!("{}: {:?}", duration.name, duration.duration);
    }
}
