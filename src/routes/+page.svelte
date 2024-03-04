<script lang="ts">
  import Card, { Content, Actions } from "@smui/card";
  import Button from "@smui/button";
  export let data: Record<string, { path: string; version: string }>;

  export function goToBalatro(index: string) {
    window.location.href = `/balatro/${index}`;
  }
</script>

<h1>Balamod</h1>
{#each Object.entries(data) as [index, { path, version }]}
  <div class="card-container">
    <Card>
      <Content>Balatro {version}</Content>
      <Content>{path}</Content>
      <Actions fullBleed>
        <Button on:click={() => goToBalatro(index)}>
          <i class="material-icons" aria-hidden="true">arrow_forward</i>
        </Button>
      </Actions>
    </Card>
  </div>
{/each}
