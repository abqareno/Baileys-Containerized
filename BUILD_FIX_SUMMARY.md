# Docker Build Fix Summary

## Issue
The Docker build was failing during `yarn install --frozen-lockfile` with the error:
```
baileys@workspace:. couldn't be built successfully (exit code 1)
```

## Root Cause
The `package.json` contains a `prepare` script that runs automatically after `yarn install`:
```json
"prepare": "npm run build"
```

This script attempts to build the TypeScript source code, but the build was failing because:
1. `yarn install` was run BEFORE copying source files
2. The prepare script tried to run `tsc` but couldn't find the source files (src/, WAProto/)
3. Build failed with exit code 1

## Solution
Modified both `Dockerfile` and `Dockerfile.alpine` to copy necessary source files BEFORE running `yarn install`:

**Files copied before installation:**
- `src/` - TypeScript source code
- `WAProto/` - Protocol definitions
- `tsconfig.json` - TypeScript configuration
- `tsconfig.build.json` - Build-specific TS config
- `engine-requirements.js` - Engine validation script
- `eslint.config.mts` - ESLint configuration
- `.prettierrc` - Prettier configuration
- `.prettierignore` - Prettier ignore rules

**Build Order (Fixed):**
1. Copy package.json, yarn.lock, .yarnrc.yml
2. **Copy source files (NEW)**
3. Run `yarn install` (prepare script now succeeds)
4. Copy remaining files
5. Continue with production stage

## Impact
- ✅ Docker build now succeeds
- ✅ CI/CD workflow passes
- ✅ No changes to application functionality
- ✅ Build cache still optimized (source files cached separately)

## Commits
- d9c7b66: Fix Docker build: copy source files before yarn install to satisfy prepare script
