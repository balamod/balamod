// Prevents additional console window on Windows in release, DO NOT REMOVE!!
#![cfg_attr(not(debug_assertions), windows_subsystem = "windows")]

use balamod_lib::{balamod::{find_balatros, Balatro}, injector::{auto_injection, backup_balatro_exe, decompile_game, restore_balatro_backup}};
use balamod_lib::duration::StepDuration;

#[tauri::command]
fn tauri_find_balatros() -> Vec<Balatro> {
  find_balatros()
}

#[tauri::command]
fn tauri_get_balatro() -> Balatro {
  find_balatros().first().unwrap().clone()
}

#[tauri::command]
fn tauri_decompile(balatro: Balatro, output_folder: String) -> Vec<StepDuration> {
  let mut durations: Vec<StepDuration> = Vec::new();
  decompile_game(balatro.clone(), Some(output_folder), &mut durations);
  durations
}

#[tauri::command]
fn tauri_inject(balatro: Balatro) -> Vec<StepDuration> {
  let mut durations: Vec<StepDuration> = Vec::new();
  backup_balatro_exe(balatro.clone());
  auto_injection(balatro.clone(), &mut durations);
  durations
}

#[tauri::command]
fn tauri_restore(balatro: Balatro) -> Vec<StepDuration> {
  let mut durations: Vec<StepDuration> = Vec::new();
  restore_balatro_backup(balatro.clone(), &mut durations);
  durations
}

fn main() {
  tauri::Builder::default()
    .invoke_handler(tauri::generate_handler![
      tauri_find_balatros,
      tauri_get_balatro,
      tauri_decompile,
      tauri_inject,
      tauri_restore,
    ])
    .run(tauri::generate_context!())
    .expect("error while running tauri application");
}
