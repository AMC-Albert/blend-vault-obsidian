# Obsidian Plugins Workspace

This workspace manages shared dependencies for all Obsidian plugins in this vault, providing significant space savings and streamlined dependency management.

## Directory Structure

```
.obsidian/plugins/
├── .workspace/                         # Centralized workspace management
│   ├── node_modules/                   # Shared dependencies (592MB)
│   ├── pnpm-store/                     # pnpm package cache
│   ├── package.json                    # Workspace configuration
│   ├── pnpm-workspace.yaml             # Workspace packages definition
│   ├── pnpm-lock.yaml                  # Dependency lock file
│   ├── .npmrc                          # pnpm configuration
│   └── setup-workspace.ps1             # Management script
├── asset-increment/                    # Individual plugin directories
├── click-unsupported-files/
├── copy-absolute-path/
├── obsidian-blender-build-manager/
├── obsidian-quick-dates/
├── obsidian-subversion/
├── obsidian-video-fragments/
├── sidecars/
└── ... (other plugins)
```

## Benefits

- **Space Savings**: Reduced from ~2.8GB to ~1.1GB total (including shared workspace)
- **Faster Installs**: Shared dependency cache accelerates installations
- **Consistency**: All plugins use the same versions of common dependencies
- **Parallel Operations**: Build/dev commands can run across all plugins simultaneously

## Usage

All workspace management operations are performed from within the `.workspace` directory:

```powershell
# Navigate to the workspace directory
cd .workspace

# Install dependencies for all plugins
pnpm install

# Build all plugins in parallel
pnpm run --parallel build

# Run dev mode for all plugins  
pnpm run --parallel dev

# Check workspace status
.\setup-workspace.ps1 -Status

# Clean everything (removes all node_modules)
.\setup-workspace.ps1 -Clean
```

### Individual Plugin Operations

For operations on specific plugins, navigate to the plugin directory and use standard npm scripts:

```powershell
```powershell
# Navigate to any plugin directory
cd ../sidecars

# Standard npm scripts work as expected
npm run build
npm run dev
```

## Configuration

### Workspace Files
- **`pnpm-workspace.yaml`** - Defines which packages are part of the workspace
- **`package.json`** - Shared devDependencies and workspace scripts
- **`.npmrc`** - pnpm configuration for optimal performance
- **`setup-workspace.ps1`** - Management and status script

### Adding New Plugins

To include a new plugin in the workspace:

1. Add the plugin path to `pnpm-workspace.yaml`
2. Add the plugin path to `package.json` workspaces array  
3. Run `pnpm install` to include in workspace

## Space Usage

| Category | Size | Description |
|----------|------|-------------|
| Shared .workspace | 593MB | Single shared node_modules |
| Individual plugins | ~555MB | Plugin-specific symlinked dependencies |
| **Total** | **~1.1GB** | **79% reduction from original 2.8GB** |

## Troubleshooting

### Rebuild Workspace
```powershell
.\setup-workspace.ps1 -Clean
pnpm install
```

### Check Status

```powershell
.\setup-workspace.ps1 -Status
```

### Reset to Individual node_modules

```powershell
.\setup-workspace.ps1 -Clean
# Then install dependencies individually in each plugin
```

## Notes

- Individual plugin `package.json` files remain unchanged
- All existing build processes continue to work normally
- pnpm handles linking automatically - no manual intervention needed
- ESLint version warnings are cosmetic and don't affect functionality
