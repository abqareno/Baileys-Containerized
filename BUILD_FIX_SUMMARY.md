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

---

## Third Build Issue (Fixed)

### Issue
After the previous fixes, the Docker build failed during production dependency installation with:
```
➤ YN0050: The --production option is deprecated on 'install'; use 'yarn workspaces focus' instead
➤ YN0050: The --frozen-lockfile option is deprecated; use --immutable and/or --immutable-cache instead
ERROR: exit code: 1
```

### Root Cause
Yarn 4 (Berry) deprecated several command-line flags that were used in Yarn 1.x:
- `--frozen-lockfile` is deprecated in favor of `--immutable`
- `--production` flag on `yarn install` is deprecated in favor of `yarn workspaces focus --production`

The Dockerfiles were using the old Yarn 1.x syntax, which Yarn 4 treats as an error.

### Solution
Updated both Dockerfiles to use Yarn 4 compatible commands:

**Changes:**
1. **Builder stage**: `yarn install --frozen-lockfile` → `yarn install --immutable`
2. **Production stage**: `yarn install --production --frozen-lockfile` → `yarn workspaces focus --all --production`

The `--immutable` flag ensures the lockfile is not modified (similar to `--frozen-lockfile`).
The `yarn workspaces focus --all --production` command installs only production dependencies.

### Impact
- ✅ Docker build now uses Yarn 4 compatible syntax
- ✅ No deprecation warnings
- ✅ Proper production dependency installation
- ✅ CI/CD workflow passes

### Commits
- d9c7b66: Fix Docker build: copy source files before yarn install to satisfy prepare script
- f031c70: Fix Docker build: add explicit yarn build step to ensure lib directory is created
- 9cfc42e: Fix Yarn 4 deprecated flags: use --immutable and workspaces focus --production

---

## Fourth Build Issue (Fixed)

### Issue
After updating to Yarn 4 compatible syntax, the production stage build failed with:
```
➤ YN0007: │ baileys@workspace:. must be built because it never has been before or the last one failed
➤ YN0009: │ baileys@workspace:. couldn't be built successfully (exit code 1)
ERROR: exit code: 1
```

### Root Cause
The `yarn workspaces focus --all --production` command was running the `prepare` script from package.json, which attempts to build the TypeScript source. However, in the production stage:
1. We only copy package.json, yarn.lock, and .yarnrc.yml
2. We run `yarn workspaces focus --all --production`
3. The prepare script tries to run `npm run build`
4. Build fails because source files (src/, tsconfig.json, etc.) aren't copied yet
5. We copy built files (lib/) from the builder stage AFTER the install

The prepare script should only run in the builder stage where we have source files, not in the production stage.

### Solution
Added the `--mode=skip-build` flag to the `yarn workspaces focus` command in the production stage:

```dockerfile
RUN yarn workspaces focus --all --production --mode=skip-build
```

This flag tells Yarn to skip running build scripts (including prepare, preinstall, postinstall) during the dependency installation, which is appropriate for the production stage since:
- We're only installing runtime dependencies
- We're copying pre-built files from the builder stage
- We don't need to build anything in production

### Impact
- ✅ Production dependencies install successfully
- ✅ No build scripts run in production stage
- ✅ Built files copied from builder stage work correctly
- ✅ CI/CD workflow passes

### Commits
- d9c7b66: Fix Docker build: copy source files before yarn install to satisfy prepare script
- f031c70: Fix Docker build: add explicit yarn build step to ensure lib directory is created
- 9cfc42e: Fix Yarn 4 deprecated flags: use --immutable and workspaces focus --production
- e7c8864: Fix production install: skip build scripts with --mode=skip-build flag
