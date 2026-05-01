# **SwiftLens — Actionable Build Plan**

## **Phase 0 — Foundation Decisions**

### **1. Create repository**

## **Tasks**

- Create separate Git repository: `swiftlens`
- Keep independent from Alfred repo
- Add initial structure:

```text
swiftlens/
├── Package.swift
├── Sources/
├── Tests/
├── docs/
├── examples/
├── scripts/
└── README.md
```

## **Done when**

- repo exists
- builds empty Swift package

---

### **2. Define governance baseline**

## **Tasks**

- Copy finalized PRD/spec docs into:

```text
docs/
```

Recommended:

```text
docs/
├── prd.md
├── architecture.md
├── rule-engine.md
└── implementation-plan.md
```

- Freeze V1 scope
- Explicitly reject scope creep

## **Done when**

- project decisions are durable
- no architecture ambiguity remains

---

## **Phase 1 — Swift Package Setup**

### **3. Create executable Swift package**

## **Tasks**

Run:

```bash
swift package init --type executable
```

Refactor into:

```text
Sources/
└── SwiftLensCLI/
```

Add test target:

```text
Tests/
└── SwiftLensTests/
```

Declare an executable product named `swiftlens` that targets `SwiftLensCLI` so `swift run swiftlens --help` is the canonical launch path.

## **Done when**

```bash
swift run swiftlens --help
```

works

---

### **4. Add package dependencies**

## **Tasks**

Add only:

| **Dependency**       | **Purpose**         |
| -------------------- | ------------------- |
| SwiftSyntax          | AST parsing         |
| Yams (or equivalent) | YAML config parsing |

Avoid extra dependencies.

## **Done when**

- package resolves cleanly
- no unnecessary libraries added

---

### **5. Create CLI command structure**

## **Tasks**

Initial commands:

```text
swiftlens scan
swiftlens validate-config
swiftlens version
swiftlens help
```

Support flags:

```text
--config
--format
--path
--verbose
```

## **Done when**

CLI contract is stable

---

## **Phase 2 — Config + Project Discovery**

###

###

### **6. Create**

**`.swiftlens.yml`**

**schema**

## **Tasks**

Implement a deterministic config schema with explicit precedence:

```yaml
project:
packs:
rules:
```

Validation required for:

- missing fields
- invalid severity
- bad paths
- invalid rule config
- unknown keys
- invalid pack names
- invalid rule IDs

Minimum schema shape:

- `project.path`: repo root or scan root
- `project.include`: optional glob list
- `project.exclude`: optional glob list
- `packs.<pack>.enabled`: boolean
- `packs.<pack>.severityOverrides`: optional rule severity map
- `rules.<rule>.enabled`: boolean
- `rules.<rule>.severity`: optional override
- `rules.<rule>.config`: rule-specific parameters

Precedence rules:

- built-in rule defaults provide the base severity and rule config
- `packs.<pack>.severityOverrides` overrides the built-in severity for rules in that pack
- `rules.<rule>.severity` overrides both built-in severity and any pack-level override
- `rules.<rule>.config` merges over built-in rule config; unknown keys fail validation
- CLI flags only affect execution scope and reporter selection, not rule severity or rule config

## **Done when**

bad config exits:

```text
exit code 2
```

---

### **7. Build project discovery layer**

## **Tasks**

Support:

- Xcode projects
- Swift Packages
- source root detection
- include/exclude patterns

Use:

```bash
xcodebuild -list
xcodebuild -showBuildSettings
swift package describe
```

Discovery rules:

- if `Package.swift` exists, treat the repository as an SPM project and use Swift Package metadata first
- if an `.xcodeproj` or `.xcworkspace` exists, use `xcodebuild` discovery
- if both exist, prefer the configured `project.path` in `.swiftlens.yml`

## **Done when**

tool can reliably locate Swift files

---

## **Phase 3 — Parser + Syntax Index**

### **8. Build SwiftSyntax parser**

## **Tasks**

Detect:

- `struct X: View`
- `body`
- protocols
- classes
- functions
- imports
- comments
- navigation patterns

Store:

- file path
- source ranges
- declaration metadata

## **Done when**

AST model is queryable

---

### **9. Create symbol/declaration index**

## **Tasks**

Build:

- declaration index
- file ownership map
- feature root ownership
- reference prep for future V2

## **Done when**

rules can query project structure

---

## **Phase 4 — First Rules**

### **10. Implement rule engine core**

## **Tasks**

Create:

```swift
protocol SwiftLensRule
```

and:

```swift
Violation
RuleContext
Severity
Confidence
FixPattern
```

`Violation` must carry:

- stable rule ID
- pack name
- severity
- confidence
- file path
- source range
- reason
- `fixPattern`
- reporter output must use `fixPattern` as the canonical public field name

## **Done when**

rules can execute consistently

---

### **11. Ship first 3 rules only**

## **Tasks**

Start with:

| **Rule**             | **Why**                   |
| -------------------- | ------------------------- |
| `AppRouterOnly`      | highest Alfred value      |
| `MassiveSwiftUIView` | generic + easy validation |
| `SingleUseProtocol`  | first AI-slop detector    |

Do not build all rules first.

## **Done when**

real findings appear in Alfred

### **11.1 Add remaining required architecture-pack rules**

## **Tasks**

After the first three rules are trusted, implement the remaining V1 `architecture` pack rules:

- `CrossFeatureImport`
- `OrphanRoute`
- `FeatureBoundaryViolation`
- `DuplicateOwnership`

## **Done when**

the required architecture pack is complete for V1

### **11.2 Complete the remaining required packs**

## **Tasks**

After the architecture pack is complete, finish the remaining V1 required packs:

- `swiftui-core`
- `ai-slop`
- `alfred`

## **Done when**

all V1 required packs are implemented or explicitly deferred with a documented rationale

---

### **12. Validate against Alfred repo**

## **Tasks**

Run against Alfred.

Fix:

- false positives
- rule ambiguity
- weak detection

Do not optimize before real usage.

## **Done when**

findings are trusted

---

## **Phase 5 — Reporting**

### **13. Implement output reporters**

## **Tasks**

Support:

| **Format**       | **Priority** |
| ---------------- | ------------ |
| JSON             | highest      |
| YAML             | high         |
| compact terminal | high         |
| Markdown         | high         |

## **Done when**

AI agents can consume results directly

---

### **14. Add exit-code policy**

## **Tasks**

Implement:

| **Condition**    | **Exit** |
| ---------------- | -------- |
| success          | 0        |
| advisory only    | 0        |
| error            | 1        |
| config issue     | 2        |
| internal failure | 3        |

## **Done when**

CI behavior is deterministic

---

## **Phase 6 — Alfred Integration**

### **15. Create Alfred wrapper**

## **Tasks**

Add:

```text
./tools/swiftlens.sh
```

Wrapper should call:

```bash
swiftlens scan
```

and preserve Alfred workflow.

## **Done when**

works like:

```bash
./tools/swiftlens.sh
```

---

### **16. Create Alfred policy pack**

## **Tasks**

Implement:

- `AppRouterOnly`
- `SingleSourceOfTruth`
- `NoHardcodedUserStrings`
- `AlfredIconsOnly`
- `DebugOnlyPreviewData`

## **Done when**

governance becomes executable

---

## **Phase 7 — OSS Preparation**

### **17. Create example project**

## **Tasks**

Add:

```text
examples/
```

with sample SwiftUI app

Used for:

- docs
- testing
- OSS onboarding

## **Done when**

works without Alfred dependency

---

### **18. Prepare public release**

## **Tasks**

Create:

- README
- installation docs
- rule docs
- CI examples
- GitHub Action sample

## **Done when**

project is understandable without explanation

---

# **Critical Rule**

## **Do Not Do This**

```text
build every rule first
```

Wrong.

Do this:

```text
ship 3 strong rules
→ validate
→ improve trust
→ expand
```

That is the correct execution model.
