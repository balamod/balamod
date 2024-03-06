<script lang="ts">
  import Button from "@smui/button";
  import { type Balatro, type IBalatroPageData } from "$lib/interfaces";
  import { invoke } from "@tauri-apps/api/tauri";
  import { open } from '@tauri-apps/api/dialog';

  export let data: IBalatroPageData;
  export let outputDirectory = data.defaultOutput;

  async function decompile(balatro: Balatro, output: string) {
    await invoke("tauri_decompile", { balatro, output_folder: output })
  }

  async function install(balatro: Balatro) {
    await invoke("tauri_install", { balatro })
  }

  async function restore(balatro: Balatro) {
    await invoke("tauri_restore", { balatro })
  }

  async function goBack() {
    window.location.href = "/balatro";
  }

  async function selectOutputDirectory() {
    const directory = await open({
      multiple: false,
      directory: true,
      title: 'Select decompile output directory',
      defaultPath: outputDirectory
    });
    if (directory) {
      if (Array.isArray(directory)) {
        outputDirectory = directory[0];
      } else {
        outputDirectory = directory as string;
      }
    }
  }
</script>

<div>
  <h1>Balatro {data.balatro.version}</h1>
  <p>{data.balatro.path}</p>
  <Button on:click={() => goBack()}>Go Back</Button>
  <span><Button on:click={() => decompile(data.balatro, outputDirectory)}>Decompile</Button> <Button on:click={() => selectOutputDirectory()}>Choose directory (Current: {outputDirectory})</Button></span>
  <Button on:click={() => install(data.balatro)}>Install Balamod</Button>
  <Button on:click={() => restore(data.balatro)}>Uninstall Balamod</Button>
</div>
