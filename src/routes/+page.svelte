<script lang="ts">
  import Card, { PrimaryAction } from "@smui/card";
  export let data: Record<string, { path: string; version: string }>;

  export function goToBalatro(index: string) {
    window.location.href = `/balatro/${index}`;
  }
</script>

<h1>Balamod</h1>
<div class="card-display">
  {#each Object.entries(data) as [index, { version }]}
    <div class="card-container">
      <Card>
        <PrimaryAction on:click={() => goToBalatro(index)}>
          <div class="card-display">
            <img src="/balatro_card.png" alt="balatro_card" />
            <h2>{version}</h2>
          </div>
        </PrimaryAction>
      </Card>
    </div>
  {/each}
</div>

<style>

  h1 {
    text-align: center;
  }
  .card-container {
    display: flex;
    justify-content: center;
    align-items: center;
    flex: 1;
  }
  .card-container:hover {
    cursor: pointer;
    transform: scale(1.1);
  }

  .card-display {
    display: flex;
    flex-wrap: wrap;
    justify-content: center;

  }
  img {
    width: 100%;
    height: 100%;
    position: relative;
  }

  h2 {
    position: relative;
    bottom: 25%;
  }
  .card-container > * {
    margin: 1rem;
  }
</style>
