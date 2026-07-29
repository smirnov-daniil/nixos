# Provider-independent agent model routing

Agent role files now declare only a complexity tier. The Pi extensions resolve that tier at invocation time against authenticated models from the currently selected provider and product family, so the same role files do not depend on Claude, OpenAI, or another provider-specific model ID.

The resolver recognizes common efficiency, balanced, and capability tier names. It keeps the active model when a provider exposes no meaningful tier distinction, and uses the role complexity as the default thinking level. Explicit `model` and `effort` frontmatter remain available as overrides for custom roles.
