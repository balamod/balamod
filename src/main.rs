use std::fs::File;
use std::io::Write;
use std::path::PathBuf;
use std::time::{Duration, Instant};
use std::{fs, str};
use std::process::exit;
use clap::Parser;
use colour::{
    blue, cyan, cyan_ln, green, green_ln, magenta, magenta_ln, red_ln, yellow, yellow_ln,
};

use crate::balamod::{get_save_dir, Balatro};
use crate::dependencies::balamod_version_exists;

mod balamod;
mod dependencies;
mod finder;

const VERSION: &str = env!("CARGO_PKG_VERSION");

#[derive(Parser, Debug, Clone)]
#[clap(version = VERSION)]
struct Args {
    #[clap(short = 'x', long = "inject")]
    inject: bool,
    #[clap(short = 'b', long = "balatro-path")]
    balatro_path: Option<String>,
    #[clap(short = 'v', long = "balatro-version")]
    balatro_version: Option<String>,
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
    #[clap(long = "linux-native")]
    linux_native: bool,
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
        uninstall(&mut durations, args.linux_native);
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
            install(args.balatro_version, &mut durations, args.linux_native);
        }
    }

    magenta_ln!("Total time: {:?}", global_start.elapsed());
    for duration in durations {
        magenta_ln!("{}: {:?}", duration.name, duration.duration);
    }
}

fn install(version: Option<String>, durations: &mut Vec<StepDuration>, linux_native: bool) {
    if let Some(version) = version.clone() {
        magenta_ln!("Installing Balamod v{}", version);
        if !balamod_version_exists(&version, linux_native) {
            red_ln!("Version {} does not exist!", version);
            exit(1);
        }
    } else {
        magenta_ln!("Installing latest Balamod");
    }

    let save_dir = get_save_dir(linux_native);
    if fs::metadata(save_dir.join("main.lua").as_path()).is_ok() {
        yellow_ln!("main.lua already exists, skipping modloader installation...");
        yellow_ln!("To reinstall the modloader, please uninstall it first with -u");
        return;
    }
    let start = Instant::now();
    let start_download_main = Instant::now();
    cyan_ln!("Downloading patched main.lua...");
    let main_lua = dependencies::download_patched_main().expect("Error while downloading main.lua");
    durations.push(StepDuration {
        duration: start_download_main.elapsed(),
        name: String::from("Download patched main.lua"),
    });
    green_ln!("Done!");

    let start_patch_main = Instant::now();
    cyan_ln!("Patching main.lua...");
    let mut main_lua_file =
        File::create(save_dir.join("main.lua")).expect("Error while creating main.lua");
    main_lua_file
        .write_all(&main_lua)
        .expect("Error while writing to main.lua");
    durations.push(StepDuration {
        duration: start_patch_main.elapsed(),
        name: String::from("Patch main.lua"),
    });
    green_ln!("Done!");

    let start_download_balamod = Instant::now();
    cyan_ln!("Downloading Balamod...");
    let tar = dependencies::download_tar(version.clone(), linux_native)
        .expect("Error while downloading Balamod");
    durations.push(StepDuration {
        duration: start_download_balamod.elapsed(),
        name: String::from("Download Balatro"),
    });
    green_ln!("Done!");

    let start_install_balamod = Instant::now();
    cyan_ln!("Installing Balamod...");
    dependencies::unpack_tar(save_dir.to_str().unwrap(), tar, linux_native)
        .expect("Error while installing Balamod");
    durations.push(StepDuration {
        duration: start_install_balamod.elapsed(),
        name: String::from("Install Balamod"),
    });
    green_ln!("Done!");

    let start_download_balalib = Instant::now();
    cyan_ln!("Downloading Balalib...");
    let balalib = dependencies::download_balalib(version, linux_native)
        .expect("Error while downloading Balalib");
    durations.push(StepDuration {
        duration: start_download_balalib.elapsed(),
        name: String::from("Download Balalib"),
    });

    let start_install_balalib = Instant::now();
    cyan_ln!("Installing Balalib...");
    let balalib_path = save_dir.join(dependencies::get_balalib_name(linux_native));
    let mut balalib_file = File::create(balalib_path).expect("Error while creating Balalib");
    balalib_file
        .write_all(&balalib)
        .expect("Error while writing to Balalib");
    durations.push(StepDuration {
        duration: start_install_balalib.elapsed(),
        name: String::from("Install Balalib"),
    });

    if cfg!(target_os = "linux") && linux_native {
        cyan_ln!("Changing http lib...");
        let start_change_http = Instant::now();
        let http_so_path = save_dir.join("https.so");
        let balamod_http_path = save_dir.join("balamod").join("https.so");
        fs::rename(balamod_http_path, http_so_path).expect("Error while changing http lib");
        durations.push(StepDuration {
            duration: start_change_http.elapsed(),
            name: String::from("Change http lib"),
        });
        green_ln!("Done!");
    }

    durations.push(StepDuration {
        duration: start.elapsed(),
        name: String::from("Modloader installation"),
    });
}

fn uninstall(durations: &mut Vec<StepDuration>, linux_native: bool) {
    cyan_ln!("Removing modloader...");
    let start = Instant::now();
    let save_dir = get_save_dir(linux_native);
    // delete main.lua
    let main_lua_path = save_dir.join("main.lua");
    if fs::metadata(main_lua_path.as_path()).is_ok() {
        fs::remove_file(main_lua_path.as_path()).expect("Error while deleting main.lua");
    }

    // delete balamod
    let balamod_path = save_dir.join("balamod");
    if fs::metadata(balamod_path.as_path()).is_ok() {
        fs::remove_dir_all(balamod_path.as_path()).expect("Error while deleting balamod");
    }

    durations.push(StepDuration {
        duration: start.elapsed(),
        name: String::from("Modloader uninstallation"),
    });

    green_ln!("Done!");
    cyan_ln!("Removing Balalib...");
    let start = Instant::now();
    let balalib_path = save_dir.join(dependencies::get_balalib_name(linux_native));
    if fs::metadata(balalib_path.as_path()).is_ok() {
        fs::remove_file(balalib_path.as_path()).expect("Error while deleting Balalib");
    }

    durations.push(StepDuration {
        duration: start.elapsed(),
        name: String::from("Balalib uninstallation"),
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
        balatro
            .compress_file(
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
