---
layout: default
title: Update combobox display size
parent: Front Style Guide
grand_parent: Best Practices
nav_order: 22
---

By default, combobox (as dropdown and multiselect ) height is defined at 50% of viewport vertical size. If list exceeds this value, a scroolbar appear. Of course it is a maximum size.
It is possible to redefine this size with **scrollHeight** parameter.

```ts
<p-dropdown>
  <scrollHeight="50vh">
</p-dropdown>
```

```ts
</p-multiSelect>
  <scrollHeight="50vh">
</p-multiSelect>
```

