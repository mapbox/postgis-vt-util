Contributing
============

### Organization

For easier organization and navigation each function is in its own SQL file in the `src/` directory. To edit an existing function or add a new one, edit the corresponding SQL file in `src/` and run `make` to apply your changes to the compile `postgis-vt-util.sql` file.

For ease of distribution the final compiled SQL file is tracked in the Git repository along with the individual source files. Make sure to run `make` after any edits in the `src/` directory and include updates to `README.md` and `postgis-vt-util.sql` in your commits.

### Documentation

The comment block at the top of each function must fully explain the purpose, input parameters, and output of the function, and ideally also include usage examples.

The main comment text should be formatted with Markdown in a consistent manner across all functions. These comments are automatically extracted and concatenated during the build process to populate the _Function Reference_ section of the README.

### Tests

Each function must be tested in `test/sql-test.sql`.

## Releasing a new version

Releases are published to npm via GitHub Actions.

### Steps

1. **Bump the version** in `package.json` (follow [semver](https://semver.org))
2. **Update `CHANGELOG.md`** with a summary of what changed
3. **Open a PR**, get it reviewed and merged to `master`
4. **Trigger the release** from the [Actions tab](../../actions/workflows/npm-release.yml):
   - Select **NPM release** → **Run workflow** → run from `master`

The workflow will publish to npm and create a GitHub release with auto-generated notes.

> **Note:** Only Mapbox maintainers with write access to this repository can trigger the release workflow. External contributors can open and contribute to PRs, but releases are always cut by the owning team.
