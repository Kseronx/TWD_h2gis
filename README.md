# TDWbench H2GIS Implementation

This repository contains the H2GIS implementation of the TDWbench/Moussa benchmark used to evaluate trajectory data warehouse queries over maritime AIS trajectory data. The benchmark compares an exact point-based trajectory representation with two polygonal approximations, `shape5` and `shape6`, and records both execution time and result-veracity metrics.

The project is a Java/Maven benchmark client. Each benchmark run creates a fresh H2/H2GIS database from CSV input files, loads H2GIS spatial functions, imports the benchmark schema, executes the selected query batch, and writes CSV/text output files.

## Repository Layout

| Path | Description |
| --- | --- |
| `pom.xml` | Maven project file. Builds the executable JAR with dependencies. |
| `src/main/java/connect/Connect.java` | Main benchmark runner. Parses runtime options, initializes the database, executes query batches, and writes results. |
| `src/main/java/connect/InitH2GIS.java` | H2GIS initialization utility. Loads spatial functions and executes the SQL import script. |
| `init_h2gis_import_existing_csv.sql` | H2GIS schema, CSV import logic, spatial indexes, and supporting B-tree indexes. |
| `schema_h2gis.sql` | Standalone H2GIS schema file retained for reference. |
| `add_h2gis_indexes.sql` | Additional benchmark-oriented indexes. |
| `add_h2gis_benchmark_indexes_optional.sql` | Optional index script retained for experimental runs. |
| `point_sch_workload.properties` | Workload SQL for exact point trajectories. |
| `shape5_sch_workload.properties` | Workload SQL for the `shape5` polygon approximation. |
| `shape6_sch_workload.properties` | Workload SQL for the `shape6` polygon approximation. |
| `run_obl_h2gis.sh` | SLURM wrapper used for batch execution on a Linux compute node. |
| `DATA_SOURCE.txt` | External Google Drive location of the source CSV dataset. |
| `results/h2gis_indexes/` | Final H2GIS result files generated for indexed `file` and `memory` experiments. |
| `results/h2gis/` | Earlier H2GIS raw result files kept as run artifacts. |
| `results/summary/` | Spreadsheet summaries used for cross-system comparison. |

## Requirements

- Java Development Kit 8 or newer. The Maven compiler target is Java 8; Java 17 was used in the SLURM execution scripts.
- Apache Maven 3.6 or newer.
- Network access during the first Maven build so Maven can download H2, H2GIS, and build plugins.
- Sufficient memory for the selected workload. The SLURM script uses `-Xmx80g` and requests `100G` of RAM because the thesis experiments were executed on a larger benchmark environment. Smaller local tests can use a smaller heap.
- Bash and SLURM are optional. They are only required for `run_obl_h2gis.sh`.

Maven downloads the main H2GIS-related dependencies declared in `pom.xml`:

```xml
<dependency>
  <groupId>org.orbisgis</groupId>
  <artifactId>h2gis</artifactId>
  <version>2.2.3</version>
</dependency>
<dependency>
  <groupId>com.h2database</groupId>
  <artifactId>h2</artifactId>
  <version>2.2.224</version>
</dependency>
```

## Source Data

The source CSV files are not committed to the repository. Download them from the Google Drive folder listed in `DATA_SOURCE.txt` and place them in a `csv/` directory at the repository root.

Required directory structure:

```text
csv/
  dimdate.csv
  dimsmarine.csv
  dimsport.csv
  dimtime.csv
  dimvessel.csv
  trippoints.csv
  trips.csv
  tripzones_polygons5.csv
  tripzones_polygons6.csv
```

The CSV files must contain header rows matching the column names used in `init_h2gis_import_existing_csv.sql`. Geometry columns must be stored as WKT strings, for example `POINT(...)`, `POLYGON(...)`, or `MULTIPOLYGON(...)`. WKT values containing commas must be quoted in CSV.

## Installation

From the repository root, build the executable JAR:

```bash
mvn -q -DskipTests package
```

After a successful build, the benchmark JAR should exist at:

```text
target/clientvesselstraj-1.0.0-jar-with-dependencies.jar
```

The benchmark runner initializes the database automatically before each run. If you want to test only the database import step, run:

```bash
java -cp target/clientvesselstraj-1.0.0-jar-with-dependencies.jar \
  main.java.connect.InitH2GIS "jdbc:h2:./data/vesselstraj;AUTO_SERVER=TRUE;LOCK_TIMEOUT=600000" init_h2gis_import_existing_csv.sql
```

This command creates or opens the H2 database under `./data/`, registers the H2GIS spatial alias, calls `H2GIS_SPATIAL()`, drops previous benchmark tables, recreates the schema, imports all CSV files from `./csv/`, and creates the spatial and relational indexes defined in the SQL script.

Quote H2 JDBC URLs in shell commands because they contain semicolons.

## Running The Benchmark Locally

Use `main.java.connect.Connect` as the main class:

```bash
java -Xmx16g -cp target/clientvesselstraj-1.0.0-jar-with-dependencies.jar \
  main.java.connect.Connect <batch_number> <file|memory> [jdbc_h2_url]
```

Examples:

```bash
java -Xmx16g -cp target/clientvesselstraj-1.0.0-jar-with-dependencies.jar \
  main.java.connect.Connect 1 file

java -Xmx16g -cp target/clientvesselstraj-1.0.0-jar-with-dependencies.jar \
  main.java.connect.Connect 11 memory

java -Xmx16g -cp target/clientvesselstraj-1.0.0-jar-with-dependencies.jar \
  main.java.connect.Connect 1 file "jdbc:h2:./data/vesselstraj;AUTO_SERVER=TRUE;LOCK_TIMEOUT=600000"
```

Arguments:

| Argument | Description |
| --- | --- |
| `<batch_number>` | Query category to run. Use `0` to run all categories or `1` to `12` for a single category. |
| `<file|memory>` | `file` uses a persistent H2 database under `./data/`. `memory` uses an in-memory H2 database. |
| `[jdbc_h2_url]` | Optional custom H2 JDBC URL. If omitted in `file` mode, `jdbc:h2:./data/vesselstraj;AUTO_SERVER=TRUE;LOCK_TIMEOUT=600000;IFEXISTS=TRUE` is used by the runner and normalized for initialization. |

Every invocation performs a fresh database initialization before executing the selected batch. This is intentional: it makes each batch run independent from previous runs and keeps the benchmark input state reproducible.

## Batch Map

| Batch | Query Category |
| --- | --- |
| `0` | All categories |
| `1` | `SpatialJoin_Group_NumAgg` |
| `2` | `SpatialJoin_Group_SpatialAgg` |
| `3` | `SpatialJoin_NoGroup_NoAgg` |
| `4` | `SpatialJoin_NoGroup_NumAgg` |
| `5` | `SpatialJoin_NoGroup_SpatialAgg` |
| `6` | `EquiJoin_Group_NumAgg` |
| `7` | `EquiJoin_Group_SpatialAgg` |
| `8` | `EquiJoin_NoGroup_NoAgg` |
| `9` | `EquiJoin_NoGroup_NumAgg` |
| `10` | `EquiJoin_NoGroup_SpatialAgg` |
| `11` | `NoJoin_NoGroup_NumAgg` |
| `12` | `NoJoin_NoGroup_SpatialAgg` |

## Running With SLURM

The repository includes `run_obl_h2gis.sh`, a SLURM wrapper used in the thesis experiments. It builds a clean scratch execution directory, copies the JAR, workload properties, import script, and `csv/` directory, executes the selected batch, and copies generated result files back to the project directory.

Build the JAR first:

```bash
mvn -q -DskipTests package
```

Then submit a job:

```bash
chmod +x run_obl_h2gis.sh
sbatch run_obl_h2gis.sh 1 file
sbatch run_obl_h2gis.sh 11 memory
```

The script accepts the same batch and storage-mode values as the Java runner:

```bash
sbatch run_obl_h2gis.sh <batch_number> [file|memory] [jdbc_h2_url]
```

If a custom H2 URL is passed as the third argument, quote it because it contains semicolons:

```bash
sbatch run_obl_h2gis.sh 1 file "jdbc:h2:./data/vesselstraj;AUTO_SERVER=TRUE;LOCK_TIMEOUT=600000"
```

Environment variables supported by the script:

| Variable | Default | Description |
| --- | --- | --- |
| `JAVA_HOME_DIR` | `$HOME/apps/jdk-17.0.15+6` | Java installation used by the SLURM job. |
| `SCRATCH_ROOT` | `/raid/$USER/tdw_h2gis_$SLURM_JOB_ID` | Temporary execution directory. It is deleted and recreated for every run. |

## Output Files

The runner writes files to the current working directory. For batch `1` in `file` mode the names follow this pattern:

```text
perf_file_batch01_SpatialJoin_Group_NumAgg_file_1day.csv
scale_file_batch01_SpatialJoin_Group_NumAgg_file_1day.csv
log_file_batch01_SpatialJoin_Group_NumAgg_file_1day.txt
```

`perf_file...csv` rows contain:

```text
query_pattern,representation,execution_time_ms,veracity_metrics
```

For the `point` representation the veracity field is `n/a`, because `point` is the baseline. For `shape5` and `shape6`, the remaining fields contain matches, false negatives, false positives, SSE, RMSE, and R-squared values computed against the point baseline.

`scale_file...csv` rows contain ratios between `point`, `shape5`, and `shape6` runtimes plus percentage differences. `log_file...txt` contains executed SQL statements, database initialization information, and error traces if a query fails.

## Included Results

The `results/` directory stores measured outputs from the thesis experiments:

- `results/h2gis_indexes/` contains the final H2GIS indexed results for available `file` and `memory` runs.
- `results/h2gis/` contains earlier raw H2GIS result artifacts.
- `results/summary/` contains spreadsheet summaries for performance, scale ratios, and result-veracity comparisons.

Runtime values depend on hardware, JVM settings, storage, and H2/H2GIS version. Treat the included files as the recorded thesis results, not as machine-independent constants.

In the final thesis measurements, H2GIS results were available for categories `1` to `8`, `11`, and `12`. Categories `9` and `10` were not included in the final H2GIS result set because processing time was too long in the benchmark environment.

## H2GIS-Specific Notes

- H2GIS is loaded by `InitH2GIS` with `CREATE ALIAS IF NOT EXISTS H2GIS_SPATIAL FOR "org.h2gis.functions.factory.H2GISFunctions.load"` and `CALL H2GIS_SPATIAL()`.
- WKT geometries are imported with `ST_GeomFromText(..., 4326)`.
- Spatial indexes are created with `CREATE SPATIAL INDEX` where applicable.
- Query files contain H2GIS/H2-specific translations, including `ROW_NUMBER() OVER (...)` instead of PostgreSQL `DISTINCT ON`, `PARSEDATETIME` and `DATEDIFF` for timestamp expressions, and bounding-box predicates combined with exact spatial predicates.
- The `csv/`, `data/`, H2 database files, generated logs, and generated benchmark CSV files are ignored by `.gitignore`.
