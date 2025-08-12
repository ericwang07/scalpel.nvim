# scalpel.nvim

## What is Scalpel?

Scalpel is a Neovim autocomplete plugin that improves code completion by combining traditional static analysis with language model (LLM)-based ranking. Unlike AI tools that generate code outright, often encouraging developers to mindlessly accept suggestions, this system uses LLMs solely to reorder and prioritize static completions gathered via the Language Server Protocol (LSP) and nvim-cmp.
By limiting the LLM’s role to ranking, the plugin ensures semantic correctness from LSP-validated completions while providing context-aware prioritization. This design prioritizes developer experience by offering smarter, relevant suggestions and empowering users to make informed choices rather than blindly accepting AI-generated code.
