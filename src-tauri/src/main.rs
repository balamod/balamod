// Prevents additional console window on Windows in release, DO NOT REMOVE!!
#![cfg_attr(not(debug_assertions), windows_subsystem = "windows")]

use balamod_lib::balamod::{find_balatros, Balatro};

#[tauri::command]
fn tauri_find_balatros() -> Vec<String> {
  find_balatros().iter().map(|balatro| balatro.path.to_str().unwrap().to_owned()).collect()
}

fn main() {
  tauri::Builder::default()
    .invoke_handler(tauri::generate_handler![tauri_find_balatros])
    .run(tauri::generate_context!())
    .expect("error while running tauri application");
}
