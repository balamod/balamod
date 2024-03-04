// Prevents additional console window on Windows in release, DO NOT REMOVE!!
#![cfg_attr(not(debug_assertions), windows_subsystem = "windows")]

use balamod_lib::{balamod::{find_balatros, Balatro}, injector::decompile_game};
use balamod_lib::duration::StepDuration;

#[tauri::command]
fn tauri_find_balatros() -> Vec<Balatro> {
  find_balatros()
}

#[tauri::command]
fn tauri_decompile(balatro: Balatro, output_folder: String) -> Vec<StepDuration> {
  let mut durations: Vec<StepDuration> = Vec::new();
  decompile_game(balatro, Some(output_folder), &mut durations);
  durations
}

fn main() {
  tauri::Builder::default()
    .invoke_handler(tauri::generate_handler![tauri_find_balatros])
    .run(tauri::generate_context!())
    .expect("error while running tauri application");
}
