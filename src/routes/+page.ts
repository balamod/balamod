import { invoke } from "@tauri-apps/api/tauri";

export async function load({ params }: { params: null}) {
  try {
    return await invoke("tauri_find_balatros");
  } catch (e) {
    console.error(e);
    return { "0": { "version": "0.0.0", "path": "/test"}}
  }
}
