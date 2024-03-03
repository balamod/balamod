use std::str;
use std::time::{Duration, Instant};

use clap::Parser;
use colour::{blue, cyan, cyan_ln, green, green_ln, magenta, magenta_ln, red_ln, yellow};

use crate::balamod::Balatro;

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
}
