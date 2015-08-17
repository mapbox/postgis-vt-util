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
