Codemod plan (manual in this repo):

1) Search patterns:
   - /#([0-9a-fA-F]{3,8})/g
   - /rgba?\([^\)]*\)/g
   - /hsla?\([^\)]*\)/g

2) Replace in component files with nearest semantic token via mapping table in theme.dart tokens.
   - If no clear mapping exists, add a new token in SemanticTokens and theme sets, not in components.

3) Blockers: CI step should fail if raw hex remains. (Add lints in future step.)


