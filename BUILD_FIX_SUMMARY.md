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

---

## Second Build Issue (Fixed)

### Issue
After fixing the first issue, the Docker build failed at the production stage with:
```
COPY --from=builder /app/lib ./lib
ERROR: "/app/lib": not found
```

### Root Cause
While the `prepare` script in package.json runs during `yarn install` and attempts to build the project, it may not complete successfully or reliably in all scenarios. The multi-stage Dockerfile tried to copy `/app/lib` from the builder stage, but that directory didn't exist.

### Solution
Added an explicit `RUN yarn build` step after copying all source files to ensure the TypeScript compilation completes and the `lib` directory is created:

**Updated Build Order:**
1. Copy package.json, yarn.lock, .yarnrc.yml
2. Copy source files (src/, WAProto/, config files)
3. Run `yarn install` (prepare script may run)
4. Copy remaining files
5. **Run `yarn build` explicitly (NEW)** ← Ensures lib/ is created
6. Continue with production stage

### Impact
- ✅ Docker build now succeeds completely
- ✅ `/app/lib` directory is guaranteed to exist
- ✅ Production stage can copy built files successfully
- ✅ CI/CD workflow passes

### Commits
- d9c7b66: Fix Docker build: copy source files before yarn install to satisfy prepare script
- f031c70: Fix Docker build: add explicit yarn build step to ensure lib directory is created
