
# Community Mods

This is a list of mods created by the community. If you have a mod you would like to add to this list, please create a pull request on the [Balamod repository](https://github.com/UwUDev/balamod).

- root mods repo index is available [here](https://github.com/UwUDev/balamod/blob/master/repos.index).
- root APIs repo index is available [here](https://github.com/UwUDev/balamod/blob/master/apis.index).

## Mods
| Name | Version | Description |
|------|---------|-------------|
{%- set mods_sorted = mods | sort(attribute='name') -%}
{%- for mod in mods_sorted %}
  | [{{ mod.name }}]({{ mod.url }}) | {{ mod.version }} | {{ mod.description }} |
{%- endfor %}

## APIs

TODO: Add APIs

<!--
| Name | Version | Description |
|------|---------|-------------|
-->


