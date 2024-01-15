use std::{env, fs, str};
use std::io::Write;
use std::process::Command;
use std::time::{Duration, Instant};

use clap::Parser;
use colour::{blue, cyan, cyan_ln, green, green_ln, magenta, magenta_ln, red_ln, yellow, yellow_ln};
use downloader::Downloader;

use crate::balamod::Balatro;

mod balamod;
mod luas;

const VERSION: &'static str = "0.1.6a";

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

        let mut header = [0; 13];
        header.copy_from_slice(&bytes[3..16]);

        if header.iter().all(|&x| (x >= 32 && x <= 126) || (x >= 10 && x <= 13)) {
            magenta_ln!("Balatro has already been decompiled, skipping... (if you need original sources then repair the game on Steam)");
            fs::rename("DAT1.luajit", "Balatro.lua").expect("Error while renaming file");
            green_ln!("Done!");

            cyan_ln!("Downloading lastest deobfuscation map...");
            let mut downloader = Downloader::builder()
                .parallel_requests(1)
                .build()
                .unwrap();

            let dl = downloader::Download::new(format!("https://gist.githubusercontent.com/UwUDev/a2b34bf14d5f04a04719d237549ccb88/raw/deobfmap.json?time={}", Instant::now().elapsed().as_secs().to_string().as_str()).as_str());
            downloader.download(&[dl]).unwrap();
            green_ln!("Done!");

            cyan_ln!("Deobfuscating...");
            let mut balatro_lua = fs::read_to_string("Balatro.lua").expect("Error while reading Balatro.lua");

            let deobf_start = Instant::now();
            balatro_lua = deobf(balatro_lua);
            durations.push(StepDuration {
                duration: deobf_start.elapsed(),
                name: String::from("Deobfuscation"),
            });

            let mut file = fs::File::create("Balatro.lua").expect("Error while creating file");
            file.write_all(balatro_lua.as_bytes()).expect("Error while writing file");
            green_ln!("Done!");

            if args.modloader || args.auto {
                inject_modloader(args.clone(), &mut durations);
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
            return;
        }

        if !fs::metadata("luajit-decompiler-v2.exe").is_ok() {
            yellow_ln!("Downloading luajit-decompiler-v2.exe...");
            let mut downloader = Downloader::builder()
                .parallel_requests(1)
                .build()
                .unwrap();

            let dl = downloader::Download::new("https://github.com/marsinator358/luajit-decompiler-v2/releases/latest/download/luajit-decompiler-v2.exe");
            downloader.download(&[dl]).unwrap();
            green_ln!("Done!");
        }

        let decompile_start = Instant::now();
        if cfg!(target_os = "windows") {
            cyan_ln!("Décompilation...");
            Command::new(env::current_dir().unwrap().join("luajit-decompiler-v2.exe"))
                .arg("DAT1.luajit")
                .current_dir(env::current_dir().unwrap())
                .output()
                .expect("Erreur lors de l'exécution de luajit-decompiler-v2.exe");
        } else if cfg!(target_os = "linux") {
            cyan_ln!("Decompiling...");
            Command::new("wine")
                .arg("luajit-decompiler-v2.exe")
                .arg("DAT1.luajit")
                .output()
                .expect("Error while executing luajit-decompiler-v2.exe");
            green_ln!("Done!");
        }

        if args.auto {
            if cfg!(target_os = "windows") {
                cyan_ln!("Décompilation...");
                Command::new(env::current_dir().unwrap().join("luajit-decompiler-v2.exe"))
                    .arg("main.lua")
                    .current_dir(env::current_dir().unwrap())
                    .output()
                    .expect("Erreur lors de l'exécution de luajit-decompiler-v2.exe");
            } else if cfg!(target_os = "linux") {
                cyan_ln!("Decompiling...");
                Command::new("wine")
                    .arg("luajit-decompiler-v2.exe")
                    .arg("main.lua")
                    .output()
                    .expect("Error while executing luajit-decompiler-v2.exe");
                green_ln!("Done!");
            }
        }

        durations.push(StepDuration {
            duration: decompile_start.elapsed(),
            name: String::from("Decompilation"),
        });

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

        cyan_ln!("Downloading lastest deobfuscation map...");
        let mut downloader = Downloader::builder()
            .parallel_requests(1)
            .build()
            .unwrap();

        let dl = downloader::Download::new(format!("https://gist.githubusercontent.com/UwUDev/a2b34bf14d5f04a04719d237549ccb88/raw/deobfmap.json?time={}", Instant::now().elapsed().as_secs().to_string().as_str()).as_str());
        downloader.download(&[dl]).unwrap();
        green_ln!("Done!");

        cyan_ln!("Deobfuscating...");
        let mut balatro_lua = fs::read_to_string("Balatro.lua").expect("Error while reading Balatro.lua");

        let deobf_start = Instant::now();
        balatro_lua = deobf(balatro_lua);

        durations.push(StepDuration {
            duration: deobf_start.elapsed(),
            name: String::from("Deobfuscation"),
        });

        let mut file = fs::File::create("Balatro.lua").expect("Error while creating file");
        file.write_all(balatro_lua.as_bytes()).expect("Error while writing file");
        green_ln!("Done!");

        if args.modloader || args.auto {
            inject_modloader(args.clone(), &mut durations);
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

fn inject_modloader(args: Args, durations: &mut Vec<StepDuration>) {
    cyan_ln!("Implementing modloader...");
    let mut path = std::path::PathBuf::from("Balatro.lua");
    if args.input.is_some() {
        path = std::path::PathBuf::from(args.input.unwrap());
    }

    if !path.exists() {
        red_ln!("File not found, cannot implement modloader >:(");
        return;
    }

    let mut balatro_lua = fs::read_to_string(path).expect("Error while reading Balatro.lua");
    let start = Instant::now();

    if balatro_lua.contains("mods = {}") {
        yellow_ln!("Balatro seems to already have a modloader, skipping...");
        return;
    }

    let mod_core = luas::get_mod_core();

    let mut end_index = balatro_lua.find("end").unwrap();
    end_index += 3;
    balatro_lua.insert_str(end_index, "\n\n");
    balatro_lua.insert_str(end_index + 2, mod_core);
    balatro_lua.insert_str(end_index + 2 + mod_core.len(), "\n");

    let mod_loader = luas::get_mod_loader();

    balatro_lua.push_str(mod_loader);

    let mut credits_button_index = balatro_lua.find("local credits_button").unwrap();
    credits_button_index += 20;
    balatro_lua.insert_str(credits_button_index, "\n");
    balatro_lua.insert_str(credits_button_index + 1, "    local mods_button\n");

    let mods_menu_button_code = luas::get_mods_menu_button();

    let mut credits_button_end = balatro_lua.find("credits_button = UIBox_button({").unwrap();
    credits_button_end += balatro_lua[credits_button_end..].find("})").unwrap() + 3;
    balatro_lua.insert_str(credits_button_end, &format!("\n{}", mods_menu_button_code));

    let mut credits_button_end = balatro_lua.find("			credits_button").unwrap();
    credits_button_end += "			credits_button".len();
    balatro_lua.insert_str(credits_button_end, ",\n			mods_button");

    balatro_lua = balatro_lua.replace("OPTIONS", "OPTIONS+");
    balatro_lua = balatro_lua.replace("text = G.VERSION", format!("text = G.VERSION .. \" \\nBalamod {}\"", VERSION).as_str());

    let pre_update_event = luas::get_pre_update_event();
    let update_index = balatro_lua.find("function Game.update(this, arg_298_1)").unwrap();
    balatro_lua.insert_str(update_index + "function Game.update(this, arg_298_1)".len(), "\n");
    balatro_lua.insert_str(update_index + "function Game.update(this, arg_298_1)\n".len(), pre_update_event);

    let post_update_event = luas::get_post_update_event();
    let update_index = balatro_lua.find("timer_checkpoint(\"controller\", \"update\")").unwrap();
    balatro_lua.insert_str(update_index + "timer_checkpoint(\"controller\", \"update\")".len(), "\n\n");
    balatro_lua.insert_str(update_index + "timer_checkpoint(\"controller\", \"update\")\n\n".len(), post_update_event);

    let ket_event_header = "function Controller.key_press_update(this, key_name, arg_31_2)";
    let key_event = luas::get_key_pressed_event();
    let key_event_index = balatro_lua.find(ket_event_header).unwrap();
    balatro_lua.insert_str(key_event_index + ket_event_header.len(), "\n");
    balatro_lua.insert_str(key_event_index + ket_event_header.len() + 1, key_event);


    let mut file = fs::File::create("Balatro.lua").expect("Error while creating file");
    file.write_all(balatro_lua.as_bytes()).expect("Error while writing file");

    path = std::path::PathBuf::from("main.lua");

    if !path.exists() {
        red_ln!("File not found, cannot implement modloader because main.lua is missing >:(");
        return;
    }

    let mut main_lua = fs::read_to_string(path).expect("Error while reading main.lua");
    // function love.draw()
    let draw_header = "function love.draw()";
    let draw_event_index = main_lua.find(draw_header).unwrap();

    // before end and after love.draw()
    let preceding_code = main_lua[draw_event_index..].find("end").unwrap();
    let end_index = draw_event_index + preceding_code;
    let draw_event = luas::get_post_render_event();
    main_lua.insert_str(end_index, "\n");
    main_lua.insert_str(end_index + 1, draw_event);

    let draw_event_index = main_lua.find(draw_header).unwrap();
    let draw_event = luas::get_pre_render_event();
    main_lua.insert_str(draw_event_index + draw_header.len(), "\n");
    main_lua.insert_str(draw_event_index + draw_header.len() + 1, draw_event);

    fs::remove_file("main.lua").expect("Error while deleting file");
    let mut file = fs::File::create("main.lua").expect("Error while creating file");
    file.write_all(main_lua.as_bytes()).expect("Error while writing file");


    durations.push(StepDuration {
        duration: start.elapsed(),
        name: String::from("Modloader implementation"),
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

fn deobf(balatro_lua: String) -> String {
    let deobfmap = fs::read_to_string("deobfmap.json").expect("Error while reading deobfuscation map");
    let deobfmap: serde_json::Value = serde_json::from_str(deobfmap.as_str()).expect("Error while parsing deobfuscation map");

    let mut balatro_lua = balatro_lua;

    for (key, value) in deobfmap.as_object().unwrap() {
        balatro_lua = balatro_lua.replace(key, value.as_str().unwrap());
    }

    balatro_lua
}
