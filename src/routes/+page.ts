import type { Balatro, IBalatroPageData, IDataError } from "$lib/interfaces";

export async function load({ params }): Promise<IBalatroPageData | IDataError> {
  try {
    const { invoke } = await import("@tauri-apps/api");
    const balatro: Balatro = await invoke("tauri_find_balatro", params);
    const defaultOutput = balatro.path + "/src";
    return {
      balatro,
      defaultOutput,
    };
  } catch (error) {
    return {
      balatro: {version: '1.0.0L', path: '/tmp/balatro'},
      defaultOutput: '/tmp/balatro/src',
    }
  }
}
