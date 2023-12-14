use std::fs;

mod balamod;
use clap::Parser;
use colour::{blue, cyan, cyan_ln, green, green_ln, magenta, red_ln, yellow};
use crate::balamod::Balatro;

const VERSION: &'static str = "Run this program";
#[derive(Parser, Debug)]
#[clap(version = VERSION)]
struct Args {
    #[clap(short='b', long="balatro-path")]
    balatro_path: Option<String>,
    #[clap(short='c', long="create-pack")]
    create_pack: bool,
    #[clap(short='x', long="inject-pack")]
    inject_pack: bool,
    #[clap(long="extract-textures")]
    extract_textures: bool,
    #[clap(long="extract-shaders")]
    extract_shaders: bool,
    #[clap(long="extract-sounds")]
    extract_sounds: bool,
    #[clap(long="extract-fonts")]
    extract_fonts: bool,
    #[clap(short='a', long="extract-all")]
    extract_all: bool,
    #[clap(short='i', long="input")]
    input: Option<String>,
    #[clap(short='o', long="output")]
    output: Option<String>,
}


fn main() {
    let mut args = Args::parse();

    if args.create_pack && args.inject_pack {
        red_ln!("You can't create and inject a pack at the same time!");
        return;
    }

    if !args.create_pack && !args.inject_pack {
        red_ln!("You must specify if you want to create or inject a pack!");
        return;
    }

    let balatros = balamod::find_balatros();

    let balatro: Balatro;
    if let Some(path) = args.balatro_path {
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

    if args.extract_all {
        args.extract_textures = true;
        args.extract_shaders = true;
        args.extract_sounds = true;
        args.extract_fonts = true;
    }

    if args.create_pack {
        if let Some(output) = args.output {
            balatro.extract_ressource_pack(&output, args.extract_textures, args.extract_shaders, args.extract_sounds, args.extract_fonts).expect("Error while extracting ressources");
            green_ln!("Done!")
        } else {
            red_ln!("You must specify an output directory!");
            return;
        }
    }

    if args.inject_pack {
        if let Some(input) = args.input {
            let input_built = format!("{}_built", input);
            balamod::build_textures(&input, &input_built);
            balatro.apply_built_ressource_pack(&input_built).expect("Error while applying ressources");
            cyan_ln!("Cleaning up...");
            fs::remove_dir_all(&input_built).expect("Error while deleting rebuilt ressource pack");
            green_ln!("Done!")
        } else {
            red_ln!("You must specify an input directory!");
            return;
        }
    }
}