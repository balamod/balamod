import { invoke } from "@tauri-apps/api/tauri";

// @ts-ignore
export async function load({ params }) {
	return await invoke("tauri_find_balatros");
}