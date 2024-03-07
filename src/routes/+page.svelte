<script lang="ts">
  import TopAppBar, { Row, Section, Title } from "@smui/top-app-bar";
  import IconButton from "@smui/icon-button";
  import Button, { Label } from "@smui/button";
  import { SmuiElement } from "@smui/common";
  import type { Balatro, Balatros, IBalatroPageData } from "$lib/interfaces";
  export let data: IBalatroPageData;
  export let outputDirectory = data.defaultOutput;
  import { invoke } from "@tauri-apps/api";
  import { open } from "@tauri-apps/api/dialog";

  async function decompile(balatro: Balatro, output_folder: string) {
    await invoke("tauri_decompile", { balatro, output_folder });
  }

  async function install(balatro: Balatro) {
    await invoke("tauri_install", { balatro });
  }

  async function restore(balatro: Balatro) {
    await invoke("tauri_restore", { balatro });
  }

  async function openDirectoryDialog(outputDirectory: string): Promise<string> {
    const directory = await open({
      multiple: false,
      directory: true,
      title: "Select decompile output directory",
      defaultPath: outputDirectory,
    });
    if (directory) {
      if (Array.isArray(directory)) {
        outputDirectory = directory[0];
      } else {
        outputDirectory = directory as string;
      }
    }
    return outputDirectory;
  }

  async function selectOutputDirectory() {
    outputDirectory = await openDirectoryDialog(outputDirectory);
  }
</script>

<div class="flexy">
  <div class="top-app-bar-container flexor">
    <TopAppBar
      variant="static"
      prominent={false}
      dense={true}
      color="secondary"
    >
      <Row>
        <Section>
          <Title>Balatro v{data.balatro.version}</Title>
        </Section>
      </Row>
    </TopAppBar>
    <div class="flexor-content">
      <span class="row btn-padding">
        <SmuiElement tag="pre">{data.balatro.path}</SmuiElement>
      </span>
      <span class="row">
        <div class="btn-padding">
          <Button
            color="secondary"
            variant="raised"
            on:click={() => decompile(data.balatro, outputDirectory)}
            ><Label>Decompile</Label></Button
          >
        </div>
        <SmuiElement tag="pre">{outputDirectory}</SmuiElement>
        <div class="btn-padding">
          <IconButton
            color="secondary"
            class="material-icons"
            on:click={() => selectOutputDirectory()}
          >
            folder_open
          </IconButton>
        </div>
      </span>
      <span class="row">
        <div class="btn-padding">
          <Button
            color="secondary"
            variant="raised"
            on:click={() => install(data.balatro)}
            ><Label>Install</Label></Button
          >
        </div>
        <div class="btn-padding">
          <Button
            color="secondary"
            variant="raised"
            on:click={() => restore(data.balatro)}
            ><Label>Uninstall</Label></Button
          >
        </div>
      </span>
    </div>
  </div>
</div>

<style>
  .row {
    width: 100%;
    display: flex;
    flex-flow: row nowrap;
    justify-content: space-between;
  }
  .btn-padding {
    padding: 10px;
  }

  .top-app-bar-container {
    max-width: 480px;
    width: 100%;
    height: 320px;
    border: 1px solid
      var(--mdc-theme-text-hint-on-background, rgba(0, 0, 0, 0.1));
    margin: 0 18px 18px 0;
    background-color: var(--mdc-theme-background, #fff);

    overflow: auto;
    display: inline-block;
  }

  @media (max-width: 480px) {
    .top-app-bar-container {
      margin-right: 0;
    }
  }

  .flexy {
    display: flex;
    flex-wrap: wrap;
    width: 100%;
    height: 100%;
  }

  .flexor {
    display: inline-flex;
    flex-direction: column;
  }

  .flexor-content {
    flex-basis: 0;
    height: 0;
    flex-grow: 1;
    overflow: auto;
  }
</style>
