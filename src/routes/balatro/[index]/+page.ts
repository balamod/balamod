import type { Balatros } from "$lib/interfaces";
import { invoke } from "@tauri-apps/api/tauri";

export function entries() {
  return [{ index: "1" }];
}

interface Params {
  index: string;
}

async function getBalatros(): Promise<Balatros> {
  try {
    return await invoke("tauri_find_balatros");
  } catch (e) {
    console.error(e);
    return { "0": { version: "0.0.0", path: "/test" } };
  }
}

export async function load({ params }: {params: Params}) {
  const balatros = await getBalatros();
  return balatros[params.index];
}
