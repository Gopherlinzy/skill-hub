# Requirement Taxonomy & Search Strategy

## Requirement Types and Keyword Extraction

### FEATURE_NEW (New functionality)
- Search strategy: Look for nearby modules, similar features, API route patterns
- Keywords: Extract nouns (entities, components), verbs (actions), endpoint paths
- Example: "Add user avatar upload" → keywords: ["avatar", "upload", "user profile",
  "image", "file upload", "/api/user", "multer", "S3"]

### FEATURE_MODIFY (Change existing behavior)
- Search strategy: Find the existing implementation first, then analyze delta
- Keywords: Extract the feature being modified + specific change verbs
- Example: "Change password policy to require 12 chars" → keywords: ["password",
  "validation", "policy", "min.*length", "PASSWORD_MIN", "zxcvbn"]

### FEATURE_REMOVE (Deprecate/remove)
- Search strategy: Find all references to the feature being removed
- Keywords: Feature name + common reference patterns (imports, configs, routes)
- Example: "Remove legacy XML export" → keywords: ["xml", "export", "legacy",
  "XML_EXPORT", "to_xml", "xml2js"]

### CONSTRAINT (Technical constraints)
- Search strategy: Check configuration, middleware, infrastructure files
- Keywords: Constraint-specific terms
- Example: "Response time < 200ms" → keywords: ["timeout", "cache", "performance",
  "latency", "benchmark"]

### NON_FUNCTIONAL (Quality attributes)
- Search strategy: Check test files, CI config, monitoring setup
- Keywords: Quality attribute terms
- Example: "99.9% uptime SLA" → keywords: ["health", "monitoring", "failover",
  "retry", "circuit-breaker"]

## Search Command Patterns

Primary search (code files):
```
rg -l "<keyword>" <dir> --type-add 'code:*.{ts,tsx,js,jsx,py,go,rs,java,rb,vue,svelte}' -t code
```

Config search:
```
rg -l "<keyword>" <dir> -g '*.{json,yaml,yml,toml,env,ini,conf}'
```

Test file search:
```
rg -l "<keyword>" <dir> -g '*{test,spec,_test}*'
```

Database/migration search:
```
rg -l "<keyword>" <dir> -g '*{migration,schema,model,entity}*'
```

Context-rich search (show surrounding code):
```
rg -n -C 5 "<keyword>" <file>
```
