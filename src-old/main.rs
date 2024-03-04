// Prevents additional console window on Windows in release, DO NOT REMOVE!!
#![cfg_attr(not(debug_assertions), windows_subsystem = "windows")]

use clap::Parser;
mod cli;
mod gui;
use crate::{cli::{main_cli, Args}, gui::main_gui};

fn main() {
    let args = Args::parse();
    if args.gui {
        main_gui();
    } else {
        main_cli(args);
    }
}
