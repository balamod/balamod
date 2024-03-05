<script lang="ts">
  import Button from "@smui/button";
  import { type Balatro } from "$lib/interfaces";
  export let data: Balatro;

  function decompile() {}

  function install() {}

  function restore() {}

  function goBack() {
    window.location.href = "/balatro";
  }
</script>

<div>
  <h1>Balatro {data.version}</h1>
  <p>{data.path}</p>
  <Button on:click={() => goBack()}><i></i></Button>
  <Button on:click={() => decompile()}></Button>
  <Button on:click={() => install()}></Button>
  <Button on:click={() => restore()}></Button>
</div>
