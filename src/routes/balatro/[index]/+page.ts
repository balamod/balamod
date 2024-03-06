import type { Balatros, IBalatroPageData } from "$lib/interfaces";
import { invoke } from "@tauri-apps/api/tauri";
// import { path } from '@tauri-apps/api';

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

export async function load({ params }: {params: Params}): Promise<IBalatroPageData> {
  const balatros = await getBalatros();
  const defaultOutput = window.__TAURI__ ? "/balatro_src" : ".";
  return {
    balatro: balatros[params.index],
    defaultOutput,
  };
}
